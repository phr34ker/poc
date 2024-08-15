provider "google" {
  project = "your-gcp-project-id"
  region  = "europe-west1"
}

resource "google_compute_network" "default" {
  name = "internal-alb-network"
}

resource "google_compute_subnetwork" "europe_west1_subnet" {
  name          = "europe-west1-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = "europe-west1"
  network       = google_compute_network.default.id
}

resource "google_compute_subnetwork" "europe_west3_subnet" {
  name          = "europe-west3-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "europe-west3"
  network       = google_compute_network.default.id
}

resource "google_compute_backend_service" "am_backend" {
  name                  = "am-backend"
  load_balancing_scheme = "INTERNAL_MANAGED"
  protocol              = "HTTP"
  port_name             = "http"
  backends {
    group = "projects/your-gcp-project-id/regions/europe-west1/networkEndpointGroups/am-neg-1"
  }
  backends {
    group = "projects/your-gcp-project-id/regions/europe-west1/networkEndpointGroups/am-neg-2"
  }
  backends {
    group = "projects/your-gcp-project-id/regions/europe-west3/networkEndpointGroups/am-neg-1"
  }
  backends {
    group = "projects/your-gcp-project-id/regions/europe-west3/networkEndpointGroups/am-neg-2"
  }
}

resource "google_compute_backend_service" "scim_backend" {
  name                  = "scim-backend"
  load_balancing_scheme = "INTERNAL_MANAGED"
  protocol              = "HTTP"
  port_name             = "http"
  backends {
    group = "projects/your-gcp-project-id/regions/europe-west1/networkEndpointGroups/scim-neg-1"
  }
  backends {
    group = "projects/your-gcp-project-id/regions/europe-west1/networkEndpointGroups/scim-neg-2"
  }
  backends {
    group = "projects/your-gcp-project-id/regions/europe-west3/networkEndpointGroups/scim-neg-1"
  }
  backends {
    group = "projects/your-gcp-project-id/regions/europe-west3/networkEndpointGroups/scim-neg-2"
  }
}

resource "google_compute_url_map" "default" {
  name = "internal-alb-url-map"

  default_service = google_compute_backend_service.am_backend.id

  path_matcher {
    name            = "am-path-matcher"
    default_service = google_compute_backend_service.am_backend.id

    path_rule {
      paths   = ["/am/*"]
      service = google_compute_backend_service.am_backend.id
    }
  }

  path_matcher {
    name            = "scim-path-matcher"
    default_service = google_compute_backend_service.scim_backend.id

    path_rule {
      paths   = ["/scim/*"]
      service = google_compute_backend_service.scim_backend.id
    }
  }

  host_rule {
    hosts        = ["test.com"]
    path_matcher = "am-path-matcher"
  }

  host_rule {
    hosts        = ["test.com"]
    path_matcher = "scim-path-matcher"
  }

  default_url_redirect {
    https_redirect = true
  }
}

resource "google_compute_target_http_proxy" "default_http_proxy" {
  name   = "internal-alb-http-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_target_https_proxy" "default_https_proxy" {
  name   = "internal-alb-https-proxy"
  url_map = google_compute_url_map.default.id
  ssl_certificates = ["projects/your-gcp-project-id/global/sslCertificates/cidp-ext"]
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name        = "internal-alb-http-forwarding-rule"
  load_balancing_scheme = "INTERNAL_MANAGED"
  target      = google_compute_target_http_proxy.default_http_proxy.id
  port_range  = "80"
  network     = google_compute_network.default.id
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name        = "internal-alb-https-forwarding-rule"
  load_balancing_scheme = "INTERNAL_MANAGED"
  target      = google_compute_target_https_proxy.default_https_proxy.id
  port_range  = "443"
  network     = google_compute_network.default.id
}
