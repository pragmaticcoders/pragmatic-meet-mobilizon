<template>
  <section class="bg-white dark:bg-zinc-700 p-2 pt-0.5">
    <h1>{{ t("Resources") }}</h1>
    <p v-if="isRoot">
      {{ t("A place to store links to documents or resources of any type.") }}
    </p>
    <div class="pl-6 mt-2 flex items-center gap-3">
      <o-checkbox v-model="checkedAll" v-if="resources.length > 0">
        <span class="sr-only">{{ t("Select all resources") }}</span>
      </o-checkbox>
      <div
        class="flex items-center gap-3"
        v-if="validCheckedResources.length > 0"
      >
        <small>
          {{
            t(
              "No resources selected",
              {
                count: validCheckedResources.length,
              },
              validCheckedResources.length
            )
          }}
        </small>
        <o-button
          variant="danger"
          icon-right="delete"
          size="small"
          @click="deleteMultipleResources"
          >{{ t("Delete") }}</o-button
        >
      </div>
    </div>
    <draggable
      :list="resources"
      :sort="false"
      :group="groupObject"
      v-if="resources.length > 0"
      tag="transition-group"
      item-key="id"
    >
      <template #item="{ element }">
        <div class="flex border m-2 p-2 items-center">
          <div
            class="resource-checkbox px-2"
            :class="{ checked: checkedResources[element.id as string] }"
          >
            <o-checkbox v-model="checkedResources[element.id as string]">
              <span class="sr-only">{{ t("Select this resource") }}</span>
            </o-checkbox>
          </div>
          <resource-item
            :resource="element"
            v-if="element.type !== 'folder'"
            @delete="emit('delete', $event)"
            @rename="emit('rename', $event)"
            @move="emit('move', $event)"
          />
          <folder-item
            :resource="element"
            :group="group"
            @delete="emit('delete', $event)"
            @rename="emit('rename', $event)"
            @move="emit('move', $event)"
            v-else
          />
        </div>
      </template>
    </draggable>
    <EmptyContent icon="link" :inline="true" v-if="resources.length === 0">
      {{ t("No resources in this folder") }}
    </EmptyContent>
  </section>
</template>
<script lang="ts" setup>
import ResourceItem from "@/components/Resource/ResourceItem.vue";
import FolderItem from "@/components/Resource/FolderItem.vue";
import { reactive, ref, watch } from "vue";
import { IResource } from "@/types/resource";
import Draggable from "zhyswan-vuedraggable";
import { IGroup } from "@/types/actor";
import { useI18n } from "vue-i18n";
import EmptyContent from "@/components/Utils/EmptyContent.vue";

const props = withDefaults(
  defineProps<{ resources: IResource[]; isRoot: boolean; group: IGroup }>(),
  { isRoot: false }
);

const emit = defineEmits<{
  (e: "move", resource: IResource): void;
  (e: "rename", resource: IResource): void;
  (e: "delete", resourceID: string): void;
}>();

const { t } = useI18n({ useScope: "global" });

const groupObject: Record<string, unknown> = {
  name: "resources",
  pull: "clone",
  put: true,
};

const checkedResources = reactive<{ [key: string]: boolean }>({});

const validCheckedResources = ref<string[]>([]);

const checkedAll = ref(false);

const deleteMultipleResources = async (): Promise<void> => {
  validCheckedResources.value.forEach((resourceID) => {
    emit("delete", resourceID);
  });
};

watch(checkedAll, () => {
  props.resources.forEach(({ id }) => {
    if (!id) return;
    checkedResources[id] = checkedAll.value;
  });
});

watch(checkedResources, (newCheckedResources) => {
  const newValidCheckedResources: string[] = [];
  Object.entries(newCheckedResources).forEach(([key, value]) => {
    if (value) {
      newValidCheckedResources.push(key);
    }
  });
  validCheckedResources.value = newValidCheckedResources;
});

// Watch for changes in resources to clean up selection state
watch(() => props.resources, (newResources) => {
  const existingResourceIds = new Set(newResources.map(r => r.id).filter(Boolean));
  
  // Clean up checkedResources - remove any checked resources that no longer exist
  Object.keys(checkedResources).forEach(resourceId => {
    if (!existingResourceIds.has(resourceId)) {
      delete checkedResources[resourceId];
    }
  });
  
  // Update validCheckedResources to only include existing resources
  validCheckedResources.value = validCheckedResources.value.filter(id => 
    existingResourceIds.has(id)
  );
  
  // Update checkedAll state
  const totalResources = newResources.length;
  const checkedCount = validCheckedResources.value.length;
  checkedAll.value = totalResources > 0 && checkedCount === totalResources;
}, { deep: true });


</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
.resource-item,
.new-resource-preview {
  display: flex;
  font-size: 14px;
  border: 1px solid #c0cdd9;
  border-radius: 4px;
  // color: #444b5d;
  margin-top: 14px;
  margin-bottom: 14px;

  .resource-checkbox {
    align-self: center;
    opacity: 0.3;
  }

  &:hover .resource-checkbox,
  .resource-checkbox.checked {
    opacity: 1;
  }
}
</style>
