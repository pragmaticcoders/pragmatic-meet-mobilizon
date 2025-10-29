import { IActor } from "@/types/actor";

function convertToUsername(value: string | null): string {
  if (!value) return "";

  // Character transliteration map for Polish and other European characters
  const transliterationMap: Record<string, string> = {
    // Polish characters
    'ą': 'a', 'ć': 'c', 'ę': 'e', 'ł': 'l', 'ń': 'n', 'ó': 'o', 'ś': 's', 'ź': 'z', 'ż': 'z',
    'Ą': 'A', 'Ć': 'C', 'Ę': 'E', 'Ł': 'L', 'Ń': 'N', 'Ó': 'O', 'Ś': 'S', 'Ź': 'Z', 'Ż': 'Z',
    
    // Other European characters
    'ä': 'a', 'ö': 'o', 'ü': 'u', 'ß': 'ss',
    'Ä': 'A', 'Ö': 'O', 'Ü': 'U',
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'å': 'a', 'æ': 'ae',
    'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Å': 'A', 'Æ': 'AE',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I',
    'ò': 'o', 'ô': 'o', 'õ': 'o', 'ø': 'o',
    'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ø': 'O',
    'ù': 'u', 'ú': 'u', 'û': 'u',
    'Ù': 'U', 'Ú': 'U', 'Û': 'U',
    'ý': 'y', 'ÿ': 'y',
    'Ý': 'Y', 'Ÿ': 'Y',
    'ñ': 'n', 'Ñ': 'N',
    'ç': 'c', 'Ç': 'C',
    'ð': 'd', 'Ð': 'D',
    'þ': 'th', 'Þ': 'TH'
  };

  return value
    .toLocaleLowerCase()
    // Apply transliteration first
    .replace(/[ąćęłńóśźżäöüßàáâãåæèéêëìíîïòôõøùúûýÿñçðþ]/g, (char) => transliterationMap[char] || char)
    // Then normalize and remove combining diacritical marks (for remaining accented characters)
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s{2,}/, " ")
    .replace(/ /g, "_")
    // Convert common separators to underscores BEFORE removing non-alphanumeric characters
    .replace(/[-&+]/g, "_")
    .replace(/[^a-z0-9_]/g, "")
    .replace(/_{2,}/, "");
}

function autoUpdateUsername(
  actor: IActor,
  newDisplayName: string | null
): IActor {
  const actor2 = { ...actor };
  const oldUsername = convertToUsername(actor.name);

  if (actor.preferredUsername === oldUsername) {
    actor2.preferredUsername = convertToUsername(newDisplayName);
  }

  return actor2;
}

function validateUsername(actor: IActor): boolean {
  return actor.preferredUsername === convertToUsername(actor.preferredUsername);
}

export { autoUpdateUsername, convertToUsername, validateUsername };
