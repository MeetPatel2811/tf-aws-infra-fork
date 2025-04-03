data "aws_route53_zone" "primary_zone" {
  name         = var.domain_name
  private_zone = false
}
resource "aws_route53_record" "subdomain_record" {
  zone_id = data.aws_route53_zone.primary_zone.zone_id
  name    = var.subdomain == "" ? var.domain_name : "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.web_alb.dns_name
    zone_id                = aws_lb.web_alb.zone_id
    evaluate_target_health = true
  }
}
