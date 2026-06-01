class Home::FeedsController < ApplicationController
  include OnboardingResumable

  FEED_LIMIT = 20

  skip_before_action :remember_page
  before_action :resume_or_expire_onboarding!

  def show
    authorize :home, :feed?
    @feed_request_id = SecureRandom.uuid
    load_feed
    load_recommended_projects if first_page?
    render layout: false
  end

  private

  def load_feed
    @pagy, posts = pagy(:offset, feed_scope, limit: FEED_LIMIT)

    @feed_posts = posts.select do |post|
      post.postable.present? &&
        (!post.repost? || post.visible_repost_original_for?(current_user))
    end

    blend_recommended_posts if first_page?
    preload_feed_associations(@feed_posts)
    @liked_devlog_ids = liked_devlog_ids_for(@feed_posts)
  end

  def blend_recommended_posts
    @feed_post_sources = @feed_posts.index_with { "quality_latest" }
    recommendations = Gorse::Recommendations.new(user: current_user)
    recommended_posts = recommendations.posts(limit: 4)
    recommended_posts = recommended_posts.reject { |post| @feed_post_sources.key?(post) }

    recommended_posts.each_with_index do |post, index|
      insert_at = [ 1 + (index * 4), @feed_posts.length ].min
      @feed_posts.insert(insert_at, post)
      @feed_post_sources[post] = "recommended"
    end
  end

  def feed_scope
    Gorse::PostPayload.feed_scope(current_user)
      .joins("LEFT JOIN users feed_authors ON feed_authors.id = posts.user_id")
      .joins("LEFT JOIN projects feed_projects ON feed_projects.id = posts.project_id")
      .where("feed_projects.id IS NULL OR feed_projects.description IS NOT NULL")
      .order(Arel.sql(quality_latest_order_sql))
  end

  def quality_latest_order_sql
    <<~SQL.squish
      (
        CASE WHEN feed_authors.verification_status = 'verified' THEN 40 ELSE 0 END
        + CASE WHEN feed_projects.description IS NOT NULL AND feed_projects.description != '' THEN 10 ELSE 0 END
        + CASE WHEN feed_projects.devlogs_count > 0 THEN 10 ELSE 0 END
        + CASE WHEN feed_projects.shipped_at IS NOT NULL THEN 15 ELSE 0 END
        + COALESCE(posts.reposts_count, 0) * 3
      ) DESC,
      posts.created_at DESC
    SQL
  end

  def preload_feed_associations(posts)
    return if posts.empty?

    preload(posts, [ :user, :project ])

    grouped = posts.group_by(&:postable_type)

    if (devlogs = grouped["Post::Devlog"])
      preload(devlogs, postable: [ :post, :attachments_attachments ])
    end

    if (ships = grouped["Post::ShipEvent"])
      preload(ships, postable: { mission_submission: :mission })
    end

    if (reposts = grouped["Post::Repost"])
      preload(reposts, postable: {
        original_post: [ :user, :project, { postable: [ :post, :attachments_attachments ] } ]
      })
    end
  end

  def preload(records, associations)
    ActiveRecord::Associations::Preloader.new(records: records, associations: associations).call
  end

  def liked_devlog_ids_for(posts)
    devlog_posts = posts.select { |p| p.postable_type == "Post::Devlog" }
    return Set.new if devlog_posts.empty?

    Like.where(user: current_user, likeable_type: "Post::Devlog", likeable_id: devlog_posts.map(&:postable_id)).pluck(:likeable_id).to_set
  end

  def load_recommended_projects
    recommendations = Gorse::Recommendations.new(user: current_user)
    projects = recommendations.projects(limit: 6)

    @recommended_projects =
      if projects.any?
        projects
      else
        Gorse::ProjectPayload.recommendable_scope(current_user)
                             .with_banner_priority
                             .limit(6)
      end
  end

  def first_page?
    @pagy.nil? || @pagy.page == 1
  end
end
