import { defaultDataIdFromObject, InMemoryCache } from "@apollo/client/core";
import { possibleTypes, typePolicies } from "./utils";

export const cache = new InMemoryCache({
  addTypename: true,
  typePolicies,
  possibleTypes,
  dataIdFromObject: (object: any) => {
    if (object.__typename === "Address") {
      return object.origin_id;
    }

    // Handle Media objects - use uuid if available, fallback to combination of url + name
    if (object.__typename === "Media") {
      if (object.uuid) {
        return `Media:${object.uuid}`;
      }
      // Fallback for Media objects with null uuid - use url as identifier
      if (object.url) {
        return `Media:url:${object.url}`;
      }
      // Last resort - use default behavior
      return defaultDataIdFromObject(object);
    }

    return defaultDataIdFromObject(object);
  },
});
