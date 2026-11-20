import std;
import vulkan;

template <typename T>
// For some reason unsigned_integral includes bools?
concept Natural =
    std::unsigned_integral<T> && !std::same_as<T, bool>;

template <Natural T>
auto test_function
(T x, T y) -> T
pre(x >= 2 && y >= 3) 
{
  return x * y;
}

auto
main
() -> int
{
  const auto version = vk::enumerateInstanceVersion();

  std::println("Vulkan API version: {}.{}.{}\n", vk::apiVersionMajor(version),
               vk::apiVersionMinor(version), vk::apiVersionPatch(version));

  unsigned a{67}, b{69};
  std::println("Testing contracts and concepts: {}", test_function(a, b));
}
