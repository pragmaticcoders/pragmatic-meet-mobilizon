const useRouterMock = vi.fn(() => ({
  push: function () {
    // do nothing
  },
}));

const useRouteMock = vi.fn(() => ({
  path: "/",
  name: "Home",
  params: {},
  query: {},
}));

import { shallowMount, VueWrapper, RouterLinkStub } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import NavBar from "@/components/NavBar.vue";
import { createMockClient, MockApolloClient } from "mock-apollo-client";
import buildCurrentUserResolver from "@/apollo/user";
import { InMemoryCache } from "@apollo/client/cache";
import { describe, it, vi, expect, afterEach, beforeEach } from "vitest";
import { DefaultApolloClient } from "@vue/apollo-composable";

vi.mock("vue-router/dist/vue-router.mjs", () => ({
  useRouter: useRouterMock,
  useRoute: useRouteMock,
}));

describe("App component", () => {
  let wrapper: VueWrapper;
  let mockClient: MockApolloClient | null;
  let router: ReturnType<typeof createRouter>;

  beforeEach(async () => {
    router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: "/", name: "Home", component: { template: "<div>Home</div>" } },
        {
          path: "/search",
          name: "SEARCH",
          component: { template: "<div>Search</div>" },
        },
        {
          path: "/login",
          name: "Login",
          component: { template: "<div>Login</div>" },
        },
      ],
    });

    await router.push("/");
    await router.isReady();
  });

  const createComponent = () => {
    const cache = new InMemoryCache({ addTypename: false });

    mockClient = createMockClient({
      cache,
      resolvers: buildCurrentUserResolver(cache),
    });

    wrapper = shallowMount(NavBar, {
      global: {
        plugins: [router],
        provide: {
          [DefaultApolloClient]: mockClient,
        },
        stubs: {
          RouterLink: RouterLinkStub,
          "o-dropdown": true,
          "o-dropdown-item": true,
          "o-tooltip": true,
        },
      },
    });
  };

  afterEach(() => {
    wrapper?.unmount();
    mockClient = null;
  });

  it("renders a Vue component", async () => {
    const push = vi.fn();
    useRouterMock.mockImplementationOnce(() => ({
      push,
    }));
    createComponent();

    await wrapper.vm.$nextTick();

    expect(wrapper.exists()).toBe(true);
    expect(wrapper.html()).toMatchSnapshot();
    // expect(wrapper.findComponent({ name: "b-navbar" }).exists()).toBeTruthy();
  });
});
