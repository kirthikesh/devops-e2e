resource "aws_ecr_repository" "this" {
  for_each             = toset(["api", "frontend"])
  name                 = "${var.project}-${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # lets `terraform destroy` clean up

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 20 images"
      selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 20 }
      action       = { type = "expire" }
    }]
  })
}
