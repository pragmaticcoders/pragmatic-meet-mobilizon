import { SEARCH_PERSONS } from "@/graphql/search";
import { VueRenderer } from "@tiptap/vue-3";
import tippy from "tippy.js";
import MentionList from "./MentionList.vue";
import { apolloClient } from "@/vue-apollo";
import { IPerson } from "@/types/actor";
import pDebounce from "p-debounce";
import { MentionOptions } from "@tiptap/extension-mention";
import { Editor } from "@tiptap/core";

import { Paginate } from "@/types/paginate";

const fetchItems = async (query: string): Promise<IPerson[]> => {
  console.log("[Mention fetchItems] Called with query:", query);
  try {
    if (query === "") {
      console.log("[Mention fetchItems] Empty query, returning empty array");
      return [];
    }

    console.log(
      "[Mention fetchItems] Making GraphQL query with searchText:",
      query
    );
    const res = await apolloClient.query<
      { searchPersons: Paginate<IPerson> },
      { searchText: string }
    >({
      query: SEARCH_PERSONS,
      variables: { searchText: query },
    });

    console.log("[Mention fetchItems] GraphQL response:", res.data);
    console.log(
      "[Mention fetchItems] Found persons:",
      res.data.searchPersons.elements
    );

    // Log each person's data structure
    res.data.searchPersons.elements.forEach((person, index) => {
      console.log(`[Mention fetchItems] Person ${index}:`, {
        id: person.id,
        name: person.name,
        preferredUsername: person.preferredUsername,
        domain: person.domain,
        rawPerson: person,
      });
    });

    return res.data.searchPersons.elements;
  } catch (e) {
    console.error("[Mention fetchItems] Error:", e);
    return [];
  }
};

const debouncedFetchItems = pDebounce(fetchItems, 200);

// Helper function to get a safe label, avoiding "undefined" strings
const getSafeLabel = (node: any): string => {
  console.log("[Mention getSafeLabel] Called with node:", node);
  console.log("[Mention getSafeLabel] Node attrs:", node.attrs);
  console.log("[Mention getSafeLabel] Label value:", node.attrs.label);
  console.log("[Mention getSafeLabel] ID value:", node.attrs.id);

  if (
    node.attrs.label &&
    node.attrs.label !== "undefined" &&
    node.attrs.label.trim() !== ""
  ) {
    console.log("[Mention getSafeLabel] Using label:", node.attrs.label);
    return node.attrs.label;
  }

  const fallbackId = node.attrs.id || "";
  console.log("[Mention getSafeLabel] Using fallback ID:", fallbackId);
  return fallbackId;
};

const mentionOptions: MentionOptions = {
  HTMLAttributes: {
    class: "mention",
    dir: "ltr",
  },
  renderLabel({ options, node }) {
    console.log(
      "[Mention renderLabel] Called with options:",
      options,
      "node:",
      node
    );
    const label = getSafeLabel(node);

    // Get the mention character from node attributes or fallback to @
    const mentionChar =
      node.attrs.mentionSuggestionChar || options.suggestion?.char || "@";
    console.log("[Mention renderLabel] Mention char:", mentionChar);
    console.log(
      "[Mention renderLabel] Options suggestion char:",
      options.suggestion?.char
    );
    console.log(
      "[Mention renderLabel] Node mention char:",
      node.attrs.mentionSuggestionChar
    );

    const result = `${mentionChar}${label}`;
    console.log("[Mention renderLabel] Returning:", result);
    return result;
  },
  renderText({ options, node }) {
    console.log(
      "[Mention renderText] Called with options:",
      options,
      "node:",
      node
    );
    const label = getSafeLabel(node);

    // Get the mention character from node attributes or fallback to @
    const mentionChar =
      node.attrs.mentionSuggestionChar || options.suggestion?.char || "@";
    console.log("[Mention renderText] Mention char:", mentionChar);

    const result = `${mentionChar}${label}`;
    console.log("[Mention renderText] Returning:", result);
    return result;
  },
  renderHTML({ options, node }) {
    console.log(
      "[Mention renderHTML] Called with options:",
      options,
      "node:",
      node
    );
    const label = getSafeLabel(node);

    // Get the mention character from node attributes or fallback to @
    const mentionChar =
      node.attrs.mentionSuggestionChar || options.suggestion?.char || "@";
    console.log("[Mention renderHTML] Mention char:", mentionChar);

    const result = [
      "span",
      { class: "mention", "data-id": node.attrs.id },
      `${mentionChar}${label}`,
    ] as const;
    console.log("[Mention renderHTML] Returning:", result);
    return result;
  },
  suggestion: {
    items: async ({
      query,
    }: {
      query: string;
      editor: Editor;
    }): Promise<IPerson[]> => {
      console.log("[Mention suggestion items] Called with query:", query);
      if (query === "") {
        console.log(
          "[Mention suggestion items] Empty query, returning empty array"
        );
        return [];
      }
      console.log(
        "[Mention suggestion items] Calling debouncedFetchItems with query:",
        query
      );
      const result = await debouncedFetchItems(query);
      console.log(
        "[Mention suggestion items] debouncedFetchItems returned:",
        result
      );
      return result;
    },
    render: () => {
      let component: VueRenderer;
      let popup: any;

      return {
        onStart: (props: Record<string, any>) => {
          console.log("[Mention suggestion onStart] Called with props:", props);
          component = new VueRenderer(MentionList, {
            props,
            editor: props.editor,
          });

          if (!props.clientRect) {
            console.log(
              "[Mention suggestion onStart] No clientRect, returning early"
            );
            return;
          }

          console.log("[Mention suggestion onStart] Creating tippy popup");
          popup = tippy("body", {
            getReferenceClientRect: props.clientRect,
            appendTo: () => document.body,
            content: component.element,
            showOnCreate: true,
            interactive: true,
            trigger: "manual",
            placement: "bottom-start",
          });
        },
        onUpdate(props: any) {
          component.updateProps(props);

          popup[0].setProps({
            getReferenceClientRect: props.clientRect,
          });
        },
        onKeyDown(props: any) {
          if (props.event.key === "Escape") {
            popup[0].hide();

            return true;
          }

          // eslint-disable-next-line @typescript-eslint/ban-ts-comment
          // @ts-ignore
          return component.ref?.onKeyDown(props);
        },
        onExit() {
          if (popup && popup[0]) {
            popup[0].destroy();
          }
          if (component) {
            component.destroy();
          }
        },
      };
    },
  },
};

export default mentionOptions;
