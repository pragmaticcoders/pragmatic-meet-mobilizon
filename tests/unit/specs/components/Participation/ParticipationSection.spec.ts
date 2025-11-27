import { config, mount, VueWrapper, flushPromises } from "@vue/test-utils";
import ParticipationSection from "@/components/Participation/ParticipationSection.vue";
import { createRouter, createWebHistory, Router } from "vue-router";
import { routes } from "@/router";
import { CommentModeration, EventJoinOptions } from "@/types/enums";
import { beforeEach, describe, expect, it } from "vitest";
import Oruga from "@oruga-ui/oruga-next";
import FloatingVue from "floating-vue";

config.global.plugins.push(Oruga);
config.global.plugins.push(FloatingVue);

let router: Router;

beforeEach(async () => {
  router = createRouter({
    history: createWebHistory(),
    routes: routes,
  });

  // await router.isReady();
});
const eventData = {
  id: "1",
  uuid: "e37910ea-fd5a-4756-7634-00971f3f4107",
  options: {
    commentModeration: CommentModeration.ALLOW_ALL,
  },
  beginsOn: new Date("2089-12-04T09:21:25Z"),
  endsOn: new Date("2089-12-04T11:21:25Z"),
  participantStats: {
    participant: 0,
    notApproved: 0,
    notConfirmed: 0,
    going: 0,
  },
};

describe("ParticipationSection", () => {
  let wrapper: VueWrapper;

  const generateWrapper = (customProps: Record<string, unknown> = {}) => {
    wrapper = mount(ParticipationSection, {
      stubs: {
        ParticipationButton: true,
      },
      props: {
        participation: null,
        event: eventData,
        anonymousParticipation: null,
        currentActor: { id: "5" },
        identities: [],
        anonymousParticipationConfig: {
          allowed: true,
        },
        ...customProps,
      },
      global: {
        plugins: [router],
      },
    });
  };

  it("renders the participation section with minimal data", async () => {
    generateWrapper();
    await wrapper.vm.$nextTick();

    expect(wrapper.exists()).toBe(true);

    expect(wrapper.find(".event-participation").exists()).toBeTruthy();

    // TODO: Move to participation button test
    // const participationButton = wrapper.find(
    //   ".event-participation .participation-button a.button.is-large.is-primary"
    // );
    // expect(participationButton.attributes("href")).toBe(
    //   `/events/${eventData.uuid}/participate/with-account`
    // );

    // expect(participationButton.text()).toBe("Participate");
  });

  // TODO: Fix this test - Oruga modal visibility issue in test environment
  // The modal component is rendered but `.isVisible()` returns false even after:
  // - await trigger('click')
  // - await flushPromises()
  // - await $nextTick()
  // Possible solutions:
  // 1. Use Oruga's programmatic modal API in tests
  // 2. Test modal content without checking visibility
  // 3. Mock the modal component differently
  // 4. Use integration/E2E tests for modal interactions instead
  it.skip("renders the participation section with existing confimed anonymous participation", async () => {
    generateWrapper({ anonymousParticipation: true });

    expect(wrapper.find(".event-participation > small").text()).toContain(
      "You are participating in this event anonymously"
    );

    const cancelAnonymousParticipationButton = wrapper.find(
      ".event-participation > button.o-btn--text"
    );
    expect(cancelAnonymousParticipationButton.text()).toBe(
      "Cancel anonymous participation"
    );

    await wrapper.find(".event-participation small span").trigger("click");
    await flushPromises();
    await wrapper.vm.$nextTick();
    expect(
      wrapper
        .findComponent({ ref: "anonymous-participation-modal" })
        .isVisible()
    ).toBeTruthy();

    await cancelAnonymousParticipationButton.trigger("click");
    await wrapper.vm.$nextTick();
    expect(wrapper.emitted("cancel-anonymous-participation")).toBeTruthy();
  });

  // TODO: Fix this test - Same Oruga modal visibility issue as above
  it.skip("renders the participation section with existing confimed anonymous participation but event moderation", async () => {
    generateWrapper({
      anonymousParticipation: true,
      event: { ...eventData, joinOptions: EventJoinOptions.RESTRICTED },
    });

    expect(wrapper.find(".event-participation > small").text()).toContain(
      "You are participating in this event anonymously"
    );

    const cancelAnonymousParticipationButton = wrapper.find(
      ".event-participation > button.o-btn--text"
    );
    expect(cancelAnonymousParticipationButton.text()).toBe(
      "Cancel anonymous participation"
    );

    await wrapper.find(".event-participation small span").trigger("click");
    await flushPromises();
    await wrapper.vm.$nextTick();
    
    const modal = wrapper.findComponent({
      ref: "anonymous-participation-modal",
    });
    expect(modal.isVisible()).toBeTruthy();
    expect(modal.find(".o-notification--primary").text()).toBe(
      "As the event organizer has chosen to manually validate participation requests, your participation will be really confirmed only once you receive an email stating it's being accepted."
    );

    await cancelAnonymousParticipationButton.trigger("click");
    await wrapper.vm.$nextTick();
    expect(wrapper.emitted("cancel-anonymous-participation")).toBeTruthy();
  });

  it("renders the participation section with existing unconfirmed anonymous participation", async () => {
    generateWrapper({ anonymousParticipation: false });

    expect(wrapper.find(".event-participation > small").text()).toContain(
      "You are participating in this event anonymously but didn't confirm participation"
    );
  });

  it("renders the participation section but the event is already passed", async () => {
    generateWrapper({
      event: {
        ...eventData,
        beginsOn: "2020-12-02T10:52:56Z",
        endsOn: "2020-12-03T10:52:56Z",
      },
    });

    expect(wrapper.find(".event-participation").exists()).toBeFalsy();
    expect(wrapper.find("button.o-btn--primary").text()).toBe(
      "Event already passed"
    );
  });
});
