{ body, ... }@request:
{
  # Request body is returned back as response body
  # Test with:
  #     curl -v http://localhost:8080/request-body -d "some body data"
  inherit body;
}
