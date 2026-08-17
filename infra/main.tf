#bucket to store website

resource "google_storage_bucket" "website" {
    name = "heaven-collection-website"
    location = "US"
}

resource "google_storage_bucket_object" "static_site_sre" {
    name = "heaven-collection.html"
    source = "../website/heaven-collection.html"
    bucket = google_storage_bucket.website.name
}
#make new object public
resource "google_storage_object_access_control" "public_rule" {
    object = google_storage_bucket_object.static_site_sre.name
    bucket = google_storage_bucket.website.name
    role = "READER"
    entity = "allUsers"
}