output "replace1" {
  value = replace("1 + 2 + 3", "+", "-")
}
output "replace2" {
  value = replace("hello world", "/w.*d/", "everybody")
}
