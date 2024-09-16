# Local variables
locals {
  default_tags = {
    Project = var.project
    Env     = var.env
    App     = var.app
  }
  cluster_name = "${var.project}-${var.env}-${var.app}-eks"
}
