module ManageHelper
  # Secondary-nav structure for the Challenge Console.
  # Grouped per the approved IA (see issue #142):
  #   Challenge (Overview, Settings) · People (Users) · Content (Sprints, Blog)
  #   · Engagement (Top Readers, Weekly Winner)
  # Chapters (#159) and Groups (#160) add their entries via their own slices.
  def console_nav_groups(challenge)
    [
      { key: "challenge", items: [
        console_nav_item("overview", challenge_manage_dashboard_path(challenge), %w[dashboard]),
        console_nav_item("settings", edit_challenge_manage_settings_path(challenge), %w[settings])
      ] },
      { key: "people", items: [
        console_nav_item("users", challenge_manage_users_path(challenge), %w[users])
      ] },
      { key: "content", items: [
        console_nav_item("sprints", challenge_manage_sprints_path(challenge), %w[sprints]),
        console_nav_item("blog", challenge_manage_blog_posts_path(challenge), %w[blog_posts])
      ] },
      { key: "engagement", items: [
        console_nav_item("top_readers", challenge_manage_top_readers_path(challenge), %w[top_readers]),
        console_nav_item("weekly_winner", challenge_seven_day_lobby_path(challenge), %w[])
      ] }
    ]
  end

  def console_nav_item(key, path, controllers)
    { key: key, label: t("manage.nav.#{key}"), path: path, active: controllers.include?(controller_name) }
  end

  # Danger zone (delete) is visible only to the challenge owner or a site admin.
  def console_danger_visible?(challenge)
    challenge.owner_or_site_admin?(current_user)
  end

  def console_nav_icon(key)
    paths = {
      "overview" => "M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6",
      "settings" => "M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z",
      "users" => "M17 20h5v-2a4 4 0 00-3-3.87M9 20H4v-2a4 4 0 013-3.87m6-1.13a4 4 0 10-4-4 4 4 0 004 4z",
      "sprints" => "M13 10V3L4 14h7v7l9-11h-7z",
      "blog" => "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z",
      "top_readers" => "M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z",
      "weekly_winner" => "M5 3h14M5 3v4a7 7 0 0014 0V3M9 21h6m-3-4v4M8 3v4a4 4 0 008 0V3"
    }
    content_tag(:svg, content_tag(:path, "", "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: paths[key]),
      class: "h-4 w-4 shrink-0", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor")
  end

  def console_nav_icon_for_danger
    content_tag(:svg, content_tag(:path, "", "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
      d: "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"),
      class: "h-4 w-4 shrink-0", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor")
  end
end
