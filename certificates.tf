resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm   = "${tls_private_key.ca.algorithm}"
  private_key_pem = "${tls_private_key.ca.private_key_pem}"

  validity_period_hours = 8760

  is_ca_certificate = true

  allowed_uses = [
    "cert_signing",
  ]

  subject {
    common_name         = "Kubernetes"
    country             = "US"
    locality            = "Portland"
    organization        = "Kubernetes"
    organizational_unit = "CA"
  }
}

resource "tls_private_key" "etcd" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "etcd" {
  key_algorithm   = "${tls_private_key.etcd.algorithm}"
  private_key_pem = "${tls_private_key.etcd.private_key_pem}"

  subject {
    common_name         = "Kubernetes"
    country             = "US"
    locality            = "Portland"
    organization        = "Kubernetes"
    organizational_unit = "CA"
  }

  dns_names = [
    "ip-${replace(lookup(var.etcd_private_ips, "zone0"), ".", "-")}",
    "ip-${replace(lookup(var.etcd_private_ips, "zone1"), ".", "-")}",
    "ip-${replace(lookup(var.etcd_private_ips, "zone2"), ".", "-")}",
  ]

  ip_addresses = [
    "${lookup(var.etcd_private_ips, "zone0")}",
    "${lookup(var.etcd_private_ips, "zone1")}",
    "${lookup(var.etcd_private_ips, "zone2")}",
    "127.0.0.1",
  ]
}

resource "tls_locally_signed_cert" "etcd" {
  cert_request_pem   = "${tls_cert_request.etcd.cert_request_pem}"
  
  ca_key_algorithm   = "${tls_private_key.ca.algorithm}"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.ca.cert_pem}"

  validity_period_hours = 8760

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "client_auth",
    "server_auth",
  ]
}
