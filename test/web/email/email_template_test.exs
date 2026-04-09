defmodule Mobilizon.Web.EmailTemplateTest do
  use ExUnit.Case, async: true

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Reports.Report
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Email.Admin

  describe "new_group_to_validate email template" do
    test "renders safe HTML in group summary" do
      group = %Actor{
        name: "Test Group",
        preferred_username: "testgroup",
        summary: "<p><strong>Foo</strong></p>"
      }

      user = %User{email: "admin@example.com", locale: "en"}

      email = Admin.new_group_to_validate(user, group)

      html_body = email.html_body

      assert html_body =~ "<strong>Foo</strong>"
      refute html_body =~ "&lt;strong&gt;"
    end

    test "renders links in group summary" do
      group = %Actor{
        name: "Test Group",
        preferred_username: "testgroup",
        summary: "<p>Check out <a href=\"https://example.com\">this link</a></p>"
      }

      user = %User{email: "admin@example.com", locale: "en"}

      email = Admin.new_group_to_validate(user, group)

      html_body = email.html_body

      assert html_body =~ ~s(<a href="https://example.com">this link</a>)
    end

    test "strips script tags from group summary" do
      group = %Actor{
        name: "Test Group",
        preferred_username: "testgroup",
        summary: "<p>Hello</p><script>alert('xss')</script><p>World</p>"
      }

      user = %User{email: "admin@example.com", locale: "en"}

      email = Admin.new_group_to_validate(user, group)

      html_body = email.html_body

      refute html_body =~ "<script>"
      refute html_body =~ "</script>"
      assert html_body =~ "<p>Hello</p>"
      assert html_body =~ "<p>World</p>"
    end

    test "removes javascript URLs from group summary" do
      group = %Actor{
        name: "Test Group",
        preferred_username: "testgroup",
        summary: "<a href=\"javascript:alert('xss')\">click me</a>"
      }

      user = %User{email: "admin@example.com", locale: "en"}

      email = Admin.new_group_to_validate(user, group)

      html_body = email.html_body

      refute html_body =~ "javascript:"
    end

    test "strips iframe from group summary" do
      group = %Actor{
        name: "Test Group",
        preferred_username: "testgroup",
        summary: "<p>Text</p><iframe src=\"https://evil.com\"></iframe><p>More</p>"
      }

      user = %User{email: "admin@example.com", locale: "en"}

      email = Admin.new_group_to_validate(user, group)

      html_body = email.html_body

      refute html_body =~ "<iframe"
      assert html_body =~ "<p>Text</p>"
      assert html_body =~ "<p>More</p>"
    end
  end

  describe "report email template" do
    setup do
      %{
        reported: build(:actor),
        reporter: build(:actor)
      }
    end

    test "renders safe HTML in content", %{reported: reported, reporter: reporter} do
      report = %Report{
        content: "<p><em>Important report</em></p>",
        url: "https://example.com/report/1",
        reported: reported,
        reporter: reporter,
        status: :open,
        events: [],
        comments: [],
        notes: [],
        id: 1
      }

      user = %User{email: "admin@example.com", locale: "en"}

      email = Admin.report(user, report)

      html_body = email.html_body

      assert html_body =~ "<em>Important report</em>"
      refute html_body =~ "&lt;em&gt;"
    end

    test "strips script tags from content", %{reported: reported, reporter: reporter} do
      report = %Report{
        content: "<p>Content</p><script>document.location='evil'</script>",
        url: "https://example.com/report/1",
        reported: reported,
        reporter: reporter,
        status: :open,
        events: [],
        comments: [],
        notes: [],
        id: 1
      }

      user = %User{email: "admin@example.com", locale: "en"}

      email = Admin.report(user, report)

      html_body = email.html_body

      refute html_body =~ "<script>"
      refute html_body =~ "</script>"
      assert html_body =~ "<p>Content</p>"
    end

    test "strips iframe from content", %{reported: reported, reporter: reporter} do
      report = %Report{
        content: "<p>Text</p><iframe src=\"https://evil.com\"></iframe>",
        url: "https://example.com/report/1",
        reported: reported,
        reporter: reporter,
        status: :open,
        events: [],
        comments: [],
        notes: [],
        id: 1
      }

      user = %User{email: "admin@example.com", locale: "en"}

      email = Admin.report(user, report)

      html_body = email.html_body

      refute html_body =~ "<iframe"
      assert html_body =~ "<p>Text</p>"
    end
  end
end