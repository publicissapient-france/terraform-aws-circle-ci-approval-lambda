resource "aws_acm_certificate" "cert" {
  provider          = aws.cloudfront
  domain_name       = "engineering.publicissapient.fr"
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  provider = aws.cloudfront
  name     = aws_acm_certificate.cert.domain_validation_options.0.resource_record_name
  type     = aws_acm_certificate.cert.domain_validation_options.0.resource_record_type
  zone_id  = data.aws_route53_zone.main.id
  records  = [aws_acm_certificate.cert.domain_validation_options.0.resource_record_value]
  ttl      = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.cloudfront
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

resource "aws_api_gateway_domain_name" "approval" {
  certificate_arn = "${aws_acm_certificate_validation.cert.certificate_arn}"
  domain_name     = "approval.engineering.publicissapient.fr"
}

resource "aws_route53_record" "approval" {
  name    = "${aws_api_gateway_domain_name.approval.domain_name}"
  type    = "A"
  zone_id = "${aws_route53_zone.approval.id}"

  alias {
    evaluate_target_health = true
    name                   = "${aws_api_gateway_domain_name.approval.cloudfront_domain_name}"
    zone_id                = "${aws_api_gateway_domain_name.approval.cloudfront_zone_id}"
  }
}

resource "aws_api_gateway_base_path_mapping" "approval" {
  api_id      = "${aws_api_gateway_rest_api.approval.id}"
  stage_name  = "${aws_api_gateway_deployment.approval.stage_name}"
  domain_name = "${aws_api_gateway_domain_name.approval.domain_name}"
}
