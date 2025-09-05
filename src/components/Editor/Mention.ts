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
  try {
    if (query === "") return [];
    const res = await apolloClient.query<
      { searchPersons: Paginate<IPerson> },
      { searchText: string }
    >({
      query: SEARCH_PERSONS,
      variables: { searchText: query },
    });
    return res.data.searchPersons.elements;
  } catch (e) {
    console.error(e);
    return [];
  }
};

const debouncedFetchItems = pDebounce(fetchItems, 200);

// Helper function to get a safe label, avoiding "undefined" strings
const getSafeLabel = (node: any): string => {
  if (node.attrs.label && 
      node.attrs.label !== "undefined" && 
      node.attrs.label.trim() !== "") {
    return node.attrs.label;
  }
  return node.attrs.id || "";
};

const mentionOptions: MentionOptions = {
  HTMLAttributes: {
    class: "mention",
    dir: "ltr",
  },
  renderLabel({ options, node }) {
    const label = getSafeLabel(node);
    return `${options.suggestion.char}${label}`;
  },
  renderText({ options, node }) {
    const label = getSafeLabel(node);
    return `${options.suggestion.char}${label}`;
  },
  renderHTML({ options, node }) {
    const label = getSafeLabel(node);
    return [
      "span",
      { class: "mention", "data-id": node.attrs.id },
      `${options.suggestion.char}${label}`,
    ];
  },
  suggestion: {
    items: async ({
      query,
    }: {
      query: string;
      editor: Editor;
    }): Promise<IPerson[]> => {
      if (query === "") {
        return [];
      }
      return await debouncedFetchItems(query);
    },
    render: () => {
      let component: VueRenderer;
      let popup: any;

      return {
        onStart: (props: Record<string, any>) => {
          component = new VueRenderer(MentionList, {
            props,
            editor: props.editor,
          });

          if (!props.clientRect) {
            return;
          }

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
