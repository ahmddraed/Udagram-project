variable "region" {
  default = "eu-north-1"
}

variable "POSTGRES_DB" {
  default = "postgres"
}

variable "POSTGRES_USER" {
  default = "udagram_user"
}

variable "DB_PORT" {
  default = "5432"
}

variable "PORT" {
  default = "8080"
}

variable "POSTGRES_PASSWORD" {
  type = string
}

variable "JWT_SECRET" {
  type = string
}