// lib/ethereum-provider.tsx

// This file mocks the window.ethereum object for testing purposes.
// It's designed to be used in environments where a real Ethereum provider
// is not available, such as a testing environment or a browser without
// MetaMask installed.

// Define a mock provider object.  This is a simplified example and can be
// extended to simulate more complex provider behavior.
const mockProvider = {
  isMetaMask: true, // Simulate MetaMask being present
  isConnected: () => true,
  request: async ({ method, params }: { method: string; params?: any }) => {
    console.log(`Mock provider received request: ${method}`, params)

    // Simulate different responses based on the method.
    switch (method) {
      case "eth_requestAccounts":
        return ["0xf39Fd6e51Ecbc6c4524E703a141153c645D8BF51"] // Mock account address
      case "eth_chainId":
        return "0x1" // Mock chain ID (Ethereum Mainnet)
      case "eth_getBalance":
        return "0xDE0B6B3A7640000" // Mock balance (1 ether)
      default:
        console.warn(`Mock provider: Unsupported method ${method}`)
        return null
    }
  },
  // Add other methods and properties as needed to simulate the Ethereum provider API.
}

// ⬇️ new safe definition — run **only** if the browser / extension
// hasn’t already injected its own provider.
if (typeof window !== "undefined" && !("ethereum" in window)) {
  Object.defineProperty(window, "ethereum", {
    configurable: false,
    writable: false,
    value: mockProvider,
  })
}

// Optional: Log a message to the console to indicate that the mock provider is active.
console.log("Mock Ethereum provider injected into window.ethereum.")
