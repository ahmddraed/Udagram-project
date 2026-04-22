import { Router, Request, Response } from "express";
import { User } from "../models/User";

import * as bcrypt from "bcrypt";
import * as jwt from "jsonwebtoken";
import { NextFunction } from "express";
import * as EmailValidator from "email-validator";

import { config } from "../../../config/config";

const router: Router = Router();

/**
 * Hash password
 */
async function generatePassword(plainTextPassword: string): Promise<string> {
  const saltRounds = 10;
  const salt = await bcrypt.genSalt(saltRounds);
  return await bcrypt.hash(plainTextPassword, salt);
}

/**
 * Compare passwords
 */
async function comparePasswords(
  plainTextPassword: string,
  hash: string
): Promise<boolean> {
  return await bcrypt.compare(plainTextPassword, hash);
}

/**
 * Generate JWT
 */
function generateJWT(user: User): string {
  return jwt.sign(user.short(), config.jwt.secret);
}

/**
 * Auth middleware
 */
export function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction
) {
  if (!req.headers?.authorization) {
    return res.status(401).send({ message: "No authorization headers." });
  }

  const tokenBearer = req.headers.authorization.split(" ");

  if (tokenBearer.length !== 2) {
    return res.status(401).send({ message: "Malformed token." });
  }

  const token = tokenBearer[1];

  return jwt.verify(token, config.jwt.secret, (err) => {
    if (err) {
      return res
        .status(401)
        .send({ auth: false, message: "Failed to authenticate." });
    }
    return next();
  });
}

/**
 * Check auth
 */
router.get(
  "/verification",
  requireAuth,
  async (_req: Request, res: Response) => {
    return res.status(200).send({ auth: true, message: "Authenticated." });
  }
);

/**
 * LOGIN
 */
router.post("/login", async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !EmailValidator.validate(email)) {
      return res
        .status(400)
        .send({ auth: false, message: "Email is invalid." });
    }

    if (!password) {
      return res
        .status(400)
        .send({ auth: false, message: "Password is required." });
    }

    const user = await User.findByPk(email);

    if (!user) {
      return res
        .status(401)
        .send({ auth: false, message: "User not found." });
    }

    const authValid = await comparePasswords(
      password,
      user.passwordHash
    );

    if (!authValid) {
      return res
        .status(401)
        .send({ auth: false, message: "Invalid password." });
    }

    const token = generateJWT(user);

    return res.status(200).send({
      auth: true,
      token,
      user: user.short(),
    });
  } catch (err) {
    console.log("LOGIN ERROR:", err);
    return res.status(500).send({ message: err });
  }
});

/**
 * REGISTER
 */
router.post("/", async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !EmailValidator.validate(email)) {
      return res.status(400).send({
        auth: false,
        message: "Email is missing or invalid.",
      });
    }

    if (!password) {
      return res.status(400).send({
        auth: false,
        message: "Password is required.",
      });
    }

    const existingUser = await User.findByPk(email);

    if (existingUser) {
      return res.status(422).send({
        auth: false,
        message: "User already exists.",
      });
    }

    const passwordHash = await generatePassword(password);

    // ✅ FIXED: use create instead of new User()
    const savedUser = await User.create({
      email,
      passwordHash,
    });

    const token = generateJWT(savedUser);

    return res.status(201).send({
      token,
      user: savedUser.short(),
    });
  } catch (err) {
    console.log("REGISTER ERROR:", err);
    return res.status(500).send({ message: err });
  }
});

/**
 * test route
 */
router.get("/", async (_req: Request, res: Response) => {
  res.send("auth working");
});

export const AuthRouter: Router = router;