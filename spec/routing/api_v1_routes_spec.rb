require "rails_helper"

# The public API is the read-only, API-key-authenticated surface described by
# /api/v1/meta. The unauthenticated CRUD endpoints that used to exist leaked
# challenge api_keys and invitation tokens and accepted anonymous writes, so
# these specs pin them as unroutable.
RSpec.describe "API v1 routes", type: :routing do
  describe "removed unauthenticated endpoints" do
    it "does not route challenge listing" do
      expect(get: "/api/v1/challenges").not_to be_routable
    end

    it "does not route challenge detail" do
      expect(get: "/api/v1/challenges/9").not_to be_routable
    end

    it "does not route challenge creation" do
      expect(post: "/api/v1/challenges").not_to be_routable
    end

    it "does not route user creation" do
      expect(post: "/api/v1/users").not_to be_routable
    end

    it "does not route reading listing or creation" do
      expect(get: "/api/v1/challenges/9/readings").not_to be_routable
      expect(post: "/api/v1/challenges/9/readings").not_to be_routable
    end

    it "does not route group listing or creation" do
      expect(get: "/api/v1/challenges/9/groups").not_to be_routable
      expect(post: "/api/v1/challenges/9/groups").not_to be_routable
    end

    it "does not route enrollment creation or update" do
      expect(post: "/api/v1/challenges/9/enrollments").not_to be_routable
      expect(patch: "/api/v1/challenges/9/enrollments/1").not_to be_routable
    end
  end

  describe "documented read-only endpoints" do
    it "routes the challenge report" do
      expect(get: "/api/v1/challenges/9/report")
        .to route_to(controller: "api/v1/challenge_reports", action: "show", id: "9")
    end

    it "routes the participant report" do
      expect(get: "/api/v1/challenges/9/participants/54")
        .to route_to(controller: "api/v1/challenge_participants", action: "show", challenge_id: "9", id: "54")
    end

    it "routes the group report" do
      expect(get: "/api/v1/challenges/9/groups/3/report")
        .to route_to(controller: "api/v1/group_reports", action: "show", challenge_id: "9", id: "3")
    end

    it "routes sprint listing and standings" do
      expect(get: "/api/v1/challenges/9/sprints")
        .to route_to(controller: "api/v1/challenge_sprints", action: "index", challenge_id: "9")
      expect(get: "/api/v1/challenges/9/sprints/2")
        .to route_to(controller: "api/v1/challenge_sprints", action: "show", challenge_id: "9", id: "2")
    end

    it "routes the meta document" do
      expect(get: "/api/v1/meta").to route_to(controller: "api/v1/meta", action: "show")
    end

    it "routes chapter verses" do
      expect(get: "/api/v1/chapter_verses").to route_to(controller: "api/v1/chapter_verses", action: "show")
    end
  end
end
