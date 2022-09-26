output "region_shortname" {
  value = join("", regex("([a-z]{2}).*-([a-z]).*-(\\d+)", "us-west-2"))
}
