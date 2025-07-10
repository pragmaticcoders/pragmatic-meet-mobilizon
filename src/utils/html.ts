export const getValueFromMeta = (name: string): string | null => {
  const element = document.querySelector(`meta[name="${name}"]`);
  if (element && element.getAttribute("content")) {
    return element.getAttribute("content");
  }
  return null;
};

/**
 * Enhanced meta tag reading with retry logic for OAuth callbacks
 * Waits for meta tags to be available, useful for timing-sensitive operations
 */
export const getValueFromMetaWithRetry = async (
  name: string,
  maxRetries: number = 10,
  delayMs: number = 100
): Promise<string | null> => {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const element = document.querySelector(`meta[name="${name}"]`);
    if (element && element.getAttribute("content")) {
      return element.getAttribute("content");
    }
    
    // Wait before next attempt
    if (attempt < maxRetries - 1) {
      await new Promise(resolve => setTimeout(resolve, delayMs));
    }
  }
  
  console.warn(`Meta tag '${name}' not found after ${maxRetries} attempts`);
  return null;
};

export function escapeHtml(html: string) {
  const p = document.createElement("p");
  p.appendChild(document.createTextNode(html.trim()));

  const escapedContent = p.innerHTML;
  p.remove();

  return escapedContent;
}
