#bucket to store website

resource "google_storage_bucket" "website" {
  name     = "heaven-collection-website"
  location = "US"
}

resource "google_storage_bucket_object" "static_site_sre" {
  name   = "heaven-collection.html"
  source = "../website/heaven-collection.html"
  bucket = google_storage_bucket.website.name
}
#make new object public
resource "google_storage_object_access_control" "public_rule" {
  object = google_storage_bucket_object.static_site_sre.name
  bucket = google_storage_bucket.website.name
  role   = "READER"
  entity = "allUsers"
}

#reserve a static ip address for the load balancer
resource "google_compute_global_address" "website_ip" {
  name = "heaven-collection-ip"
}

#get the managed DNS zone for the domain
data "google_dns_managed_zone" "website_zone" {
  name = "terraform-gcp"
}

# add the IP address to the DNS zone for the domain
resource "google_dns_record_set" "website_dns" {
  name         = "website.${data.google_dns_managed_zone.website_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.website_zone.name
  rrdatas      = [google_compute_global_address.website_ip.address]
}

# add the bucket as a CDN backend for the load balancer
resource "google_compute_backend_bucket" "website_backend" {
  name        = "heaven-collection-backend"
  bucket_name = google_storage_bucket.website.name
  description = "Backend bucket for heaven-collection website"
  enable_cdn  = true
}

# GCP URL map for the load balancer
resource "google_compute_url_map" "website_url_map" {
  name            = "heaven-collection-url-map"
  default_service = google_compute_backend_bucket.website_backend.self_link
  host_rule {
    hosts        = ["website.${data.google_dns_managed_zone.website_zone.dns_name}"]
    path_matcher = "allpaths"
  }
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.website_backend.self_link
  }
}

#GCP target HTTP proxy for the load balancer
resource "google_compute_target_http_proxy" "website_http_proxy" {
  name    = "heaven-collection-http-proxy"
  url_map = google_compute_url_map.website_url_map.self_link
}

#GCP forwarding rule for the load balancer
resource "google_compute_global_forwarding_rule" "website_forwarding_rule" {
  name                  = "heaven-collection-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website_ip.address
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.website_http_proxy.self_link
}
