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
  maxRetries: number = 20,
  delayMs: number = 150
): Promise<string | null> => {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    // Wait for DOM to be ready
    if (document.readyState !== 'complete') {
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
    
    const element = document.querySelector(`meta[name="${name}"]`);
    if (element && element.getAttribute("content")) {
      const content = element.getAttribute("content");
      console.debug(`Found meta tag '${name}' on attempt ${attempt + 1}: ${content?.substring(0, 20)}...`);
      return content;
    }

    // Progressive backoff: increase delay slightly with each attempt
    const currentDelay = delayMs + (attempt * 50);
    
    // Wait before next attempt
    if (attempt < maxRetries - 1) {
      console.debug(`Meta tag '${name}' not found, retrying in ${currentDelay}ms (attempt ${attempt + 1}/${maxRetries})`);
      await new Promise((resolve) => setTimeout(resolve, currentDelay));
    }
  }

  console.error(`Meta tag '${name}' not found after ${maxRetries} attempts. Document state: ${document.readyState}`);
  console.error(`Available meta tags: ${Array.from(document.querySelectorAll('meta[name]')).map(el => el.getAttribute('name')).join(', ')}`);
  return null;
};

export function escapeHtml(html: string) {
  const p = document.createElement("p");
  p.appendChild(document.createTextNode(html.trim()));

  const escapedContent = p.innerHTML;
  p.remove();

  return escapedContent;
}

export function stripHtmlTags(html: string): string {
  const div = document.createElement("div");
  div.innerHTML = html;
  const text = div.textContent || div.innerText || "";
  div.remove();
  return text.trim();
}
