# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120510142319) do

  create_table "actions", :force => true do |t|
    t.integer  "conversation_id"
    t.integer  "actionable_id"
    t.string   "actionable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "actions", ["actionable_id"], :name => "index_actions_on_actionable_id"
  add_index "actions", ["actionable_type"], :name => "index_actions_on_actionable_type"
  add_index "actions", ["conversation_id"], :name => "index_actions_on_conversation_id"

  create_table "actions_reflections", :id => false, :force => true do |t|
    t.integer "reflection_id"
    t.integer "action_id"
  end

  add_index "actions_reflections", ["reflection_id", "action_id"], :name => "index_actions_reflections_on_reflection_id_and_action_id"

  create_table "articles", :force => true do |t|
    t.string   "title"
    t.string   "author"
    t.text     "description"
    t.string   "link"
    t.string   "video_url"
    t.string   "percent"
    t.boolean  "current",                              :default => false
    t.boolean  "main",                                 :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.boolean  "homepage_article",                     :default => false
    t.boolean  "issue_article",                        :default => false
    t.boolean  "conversation_article",                 :default => false
    t.string   "embed_target",         :limit => 1000
    t.string   "youtube_id"
  end

  create_table "authentications", :force => true do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "token"
    t.string   "secret"
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "authentications", ["person_id"], :name => "index_authentications_on_person_id"
  add_index "authentications", ["provider"], :name => "index_authentications_on_provider"
  add_index "authentications", ["uid"], :name => "index_authentications_on_uid"

  create_table "ckeditor_assets", :force => true do |t|
    t.string   "data_file_name",                  :null => false
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "assetable_id"
    t.string   "assetable_type",    :limit => 30
    t.string   "type",              :limit => 30
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ckeditor_assets", ["assetable_type", "assetable_id"], :name => "idx_ckeditor_assetable"
  add_index "ckeditor_assets", ["assetable_type", "type", "assetable_id"], :name => "idx_ckeditor_assetable_type"

  create_table "content_item_descriptions", :force => true do |t|
    t.string "content_type"
    t.text   "description_long"
    t.text   "description_short"
  end

  create_table "content_item_links", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.text     "url"
    t.integer  "content_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_item_links", ["content_item_id"], :name => "index_content_item_links_on_content_item_id"

  create_table "content_items", :force => true do |t|
    t.integer  "person_id"
    t.string   "content_type"
    t.string   "title",              :null => false
    t.text     "summary"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cached_slug"
    t.datetime "published"
    t.text     "embed_code"
    t.string   "external_link"
    t.integer  "conversation_id"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.string   "page_title"
    t.text     "meta_description"
    t.text     "meta_tags"
    t.string   "link_text"
    t.string   "slug"
  end

  add_index "content_items", ["cached_slug"], :name => "index_content_items_on_cached_slug", :length => {"cached_slug"=>10}
  add_index "content_items", ["content_type"], :name => "index_content_items_on_content_type", :length => {"content_type"=>4}
  add_index "content_items", ["conversation_id"], :name => "index_content_items_on_conversation_id"
  add_index "content_items", ["person_id"], :name => "index_content_items_on_person_id"
  add_index "content_items", ["slug"], :name => "index_content_items_on_slug", :unique => true

  create_table "content_items_conversations", :id => false, :force => true do |t|
    t.integer  "conversation_id"
    t.integer  "content_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_items_conversations", ["conversation_id", "content_item_id"], :name => "content_items_conversations_ids_index"

  create_table "content_items_people", :force => true do |t|
    t.integer  "content_item_id"
    t.integer  "person_id"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_items_people", ["content_item_id", "person_id"], :name => "index_content_items_people_on_content_item_id_and_person_id"

  create_table "content_items_topics", :id => false, :force => true do |t|
    t.integer  "content_item_id"
    t.integer  "topic_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_items_topics", ["content_item_id", "topic_id"], :name => "index_content_items_topics_on_content_item_id_and_topic_id"

  create_table "content_templates", :force => true do |t|
    t.string   "name"
    t.text     "template"
    t.integer  "person_id"
    t.string   "cached_slug"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "stylesheet_path"
    t.string   "slug"
  end

  add_index "content_templates", ["cached_slug"], :name => "index_content_templates_on_cached_slug", :unique => true
  add_index "content_templates", ["person_id"], :name => "index_content_templates_on_person_id"
  add_index "content_templates", ["slug"], :name => "index_content_templates_on_slug", :unique => true

  create_table "contributions", :force => true do |t|
    t.datetime "datetime"
    t.integer  "owner"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "official",                                      :default => false
    t.integer  "conversation_id"
    t.integer  "parent_id"
    t.integer  "issue_id"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.integer  "total_visits"
    t.integer  "recent_visits"
    t.integer  "total_rating"
    t.integer  "recent_rating"
    t.datetime "last_visit_date"
    t.datetime "last_rating_date"
    t.string   "askee"
    t.integer  "lft"
    t.integer  "rgt"
    t.string   "url"
    t.string   "title"
    t.text     "description"
    t.string   "embed_target",            :limit => 1000
    t.boolean  "confirmed",                                     :default => true
    t.boolean  "notify"
    t.text     "embedly_code",            :limit => 2147483647
    t.string   "embedly_type"
    t.boolean  "top_level_contribution",                        :default => false
  end

  add_index "contributions", ["conversation_id"], :name => "index_contributions_on_conversation_id"
  add_index "contributions", ["issue_id"], :name => "index_contributions_on_issue_id"
  add_index "contributions", ["owner"], :name => "index_contributions_on_owner"

  create_table "conversations", :force => true do |t|
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text     "summary"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.string   "zip_code"
    t.integer  "total_visits",             :default => 0
    t.integer  "recent_visits",            :default => 0
    t.datetime "last_visit_date"
    t.integer  "total_rating"
    t.integer  "recent_rating"
    t.datetime "last_rating_date"
    t.string   "video_url"
    t.string   "audio_clip_file_name"
    t.string   "audio_clip_content_type"
    t.integer  "audio_clip_file_size"
    t.datetime "audio_clip_updated_at"
    t.integer  "owner"
    t.boolean  "staff_pick",               :default => false, :null => false
    t.integer  "position"
    t.boolean  "from_community",           :default => false
    t.string   "cached_slug"
    t.boolean  "exclude_from_most_recent", :default => false
    t.string   "page_title"
    t.text     "meta_description"
    t.text     "meta_tags"
    t.string   "slug"
  end

  add_index "conversations", ["cached_slug"], :name => "index_conversations_on_cached_slug", :unique => true
  add_index "conversations", ["exclude_from_most_recent"], :name => "index_conversations_on_exclude_from_most_recent"
  add_index "conversations", ["owner"], :name => "index_conversations_on_owner"
  add_index "conversations", ["slug"], :name => "index_conversations_on_slug", :unique => true

  create_table "conversations_issues", :id => false, :force => true do |t|
    t.integer "conversation_id"
    t.integer "issue_id"
  end

  add_index "conversations_issues", ["conversation_id", "issue_id"], :name => "index_conversations_issues_on_conversation_id_and_issue_id", :unique => true

  create_table "counties", :force => true do |t|
    t.string   "name"
    t.string   "state",      :limit => 2
    t.integer  "region_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "counties", ["region_id"], :name => "index_counties_on_region_id"

  create_table "curated_feed_items", :force => true do |t|
    t.string   "original_url",    :null => false
    t.string   "provider_url"
    t.string   "title"
    t.text     "description"
    t.datetime "pub_date"
    t.text     "raw"
    t.integer  "curated_feed_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "curated_feed_items", ["curated_feed_id"], :name => "index_curated_feed_items_on_curated_feed_id"

  create_table "curated_feeds", :force => true do |t|
    t.string   "title",       :null => false
    t.string   "description"
    t.string   "cached_slug"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  add_index "curated_feeds", ["cached_slug"], :name => "index_curated_feeds_on_cached_slug", :unique => true
  add_index "curated_feeds", ["slug"], :name => "index_curated_feeds_on_slug", :unique => true

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["locked_by"], :name => "delayed_jobs_locked_by"
  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "email_restrictions", :force => true do |t|
    t.string   "domain"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "friendly_id_slugs", :force => true do |t|
    t.string   "slug",                         :null => false
    t.integer  "sluggable_id",                 :null => false
    t.string   "sluggable_type", :limit => 40
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type"], :name => "index_friendly_id_slugs_on_slug_and_sluggable_type", :unique => true
  add_index "friendly_id_slugs", ["sluggable_id"], :name => "index_friendly_id_slugs_on_sluggable_id"
  add_index "friendly_id_slugs", ["sluggable_type"], :name => "index_friendly_id_slugs_on_sluggable_type"

  create_table "homepage_featureds", :force => true do |t|
    t.integer  "homepage_featureable_id",   :null => false
    t.string   "homepage_featureable_type", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "homepage_featureds", ["homepage_featureable_id", "homepage_featureable_type"], :name => "homepage_featureable_id_and_type", :unique => true

  create_table "issues", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "summary"
    t.integer  "total_visits"
    t.integer  "recent_visits"
    t.integer  "total_rating"
    t.integer  "recent_rating"
    t.datetime "last_visit_date"
    t.datetime "last_rating_date"
    t.string   "zip_code"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.string   "url"
    t.string   "url_title"
    t.string   "cached_slug"
    t.string   "type",                               :default => "Issue", :null => false
    t.integer  "managed_issue_page_id"
    t.integer  "position"
    t.string   "sponsor_name"
    t.boolean  "exclude_from_result",                :default => false
    t.text     "index_summary"
    t.string   "page_title"
    t.text     "meta_description"
    t.text     "meta_tags"
    t.string   "slug"
    t.string   "standard_banner_image_file_name"
    t.string   "standard_banner_image_content_type"
    t.integer  "standard_banner_image_file_size"
    t.datetime "standard_banner_image_updated_at"
    t.string   "standard_banner_image_title"
  end

  add_index "issues", ["cached_slug"], :name => "index_issues_on_cached_slug", :unique => true
  add_index "issues", ["slug"], :name => "index_issues_on_slug", :unique => true

  create_table "issues_topics", :id => false, :force => true do |t|
    t.integer  "issue_id"
    t.integer  "topic_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "issues_topics", ["issue_id", "topic_id"], :name => "index_issues_topics_on_issue_id_and_topic_id"

  create_table "managed_issue_pages", :force => true do |t|
    t.string   "name",            :null => false
    t.integer  "issue_id",        :null => false
    t.integer  "person_id",       :null => false
    t.text     "template",        :null => false
    t.string   "cached_slug"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "stylesheet_path"
    t.string   "slug"
  end

  add_index "managed_issue_pages", ["cached_slug"], :name => "index_managed_issue_pages_on_cached_slug", :unique => true
  add_index "managed_issue_pages", ["issue_id"], :name => "index_managed_issue_pages_on_issue_id"
  add_index "managed_issue_pages", ["person_id"], :name => "index_managed_issue_pages_on_person_id"
  add_index "managed_issue_pages", ["slug"], :name => "index_managed_issue_pages_on_slug", :unique => true

  create_table "organization_details", :force => true do |t|
    t.integer  "person_id"
    t.string   "street"
    t.string   "city"
    t.string   "region"
    t.string   "postal_code"
    t.string   "phone"
    t.string   "facebook_page"
    t.integer  "organization_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "organization_members", :id => false, :force => true do |t|
    t.integer  "organization_id"
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "people", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.boolean  "admin"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password"
    t.string   "email",                                  :default => "",   :null => false
    t.string   "encrypted_password",      :limit => 128, :default => "",   :null => false
    t.string   "password_salt",                          :default => "",   :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "zip_code"
    t.boolean  "proxy"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer  "failed_attempts",                        :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.text     "bio"
    t.boolean  "daily_digest",                           :default => true, :null => false
    t.boolean  "declined_fb_auth"
    t.string   "cached_slug"
    t.string   "twitter_username"
    t.string   "website"
    t.string   "avatar_url"
    t.boolean  "weekly_newsletter",                      :default => true
    t.string   "type"
    t.string   "title"
    t.string   "slug"
    t.string   "avatar_cached_image_url"
  end

  add_index "people", ["cached_slug"], :name => "index_people_on_cached_slug", :unique => true
  add_index "people", ["email"], :name => "index_people_on_email", :unique => true
  add_index "people", ["reset_password_token"], :name => "index_people_on_reset_password_token", :unique => true
  add_index "people", ["slug"], :name => "index_people_on_slug", :unique => true

  create_table "petition_signatures", :force => true do |t|
    t.integer  "petition_id"
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "petition_signatures", ["petition_id", "person_id"], :name => "index_petition_signatures_on_petition_id_and_person_id"

  create_table "petitions", :force => true do |t|
    t.integer  "conversation_id"
    t.string   "title"
    t.text     "description"
    t.text     "resulting_actions"
    t.integer  "signature_needed"
    t.date     "end_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "person_id"
  end

  add_index "petitions", ["conversation_id"], :name => "index_petitions_on_conversation_id"
  add_index "petitions", ["person_id"], :name => "index_petitions_on_person_id"

  create_table "rating_descriptors", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rating_groups", :force => true do |t|
    t.integer  "person_id"
    t.integer  "conversation_id"
    t.integer  "contribution_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rating_groups", ["contribution_id"], :name => "index_rating_groups_on_contribution_id"
  add_index "rating_groups", ["conversation_id"], :name => "index_rating_groups_on_conversation_id"
  add_index "rating_groups", ["person_id"], :name => "index_rating_groups_on_person_id"

  create_table "ratings", :force => true do |t|
    t.integer  "rating_group_id"
    t.integer  "rating_descriptor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ratings", ["rating_descriptor_id"], :name => "index_ratings_on_rating_descriptor_id"
  add_index "ratings", ["rating_group_id"], :name => "index_ratings_on_rating_group_id"

  create_table "reflection_comments", :force => true do |t|
    t.text     "body"
    t.integer  "person_id"
    t.integer  "reflection_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "reflection_comments", ["person_id"], :name => "index_reflection_comments_on_person_id"
  add_index "reflection_comments", ["reflection_id"], :name => "index_reflection_comments_on_reflection_id"

  create_table "reflections", :force => true do |t|
    t.string   "title",           :null => false
    t.text     "details",         :null => false
    t.integer  "owner",           :null => false
    t.integer  "conversation_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "regions", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.text     "description"
  end

  create_table "revision_records", :force => true do |t|
    t.string   "revisionable_type", :limit => 100, :null => false
    t.integer  "revisionable_id",                  :null => false
    t.integer  "revision",                         :null => false
    t.binary   "data"
    t.datetime "created_at",                       :null => false
  end

  add_index "revision_records", ["revisionable_type", "revisionable_id", "revision"], :name => "revisionable", :unique => true

  create_table "selected_survey_options", :force => true do |t|
    t.integer  "survey_option_id"
    t.integer  "survey_response_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "slugs", :force => true do |t|
    t.string   "name"
    t.integer  "sluggable_id"
    t.integer  "sequence",                     :default => 1, :null => false
    t.string   "sluggable_type", :limit => 40
    t.string   "scope"
    t.datetime "created_at"
  end

  add_index "slugs", ["name", "sluggable_type", "sequence", "scope"], :name => "index_slugs_on_n_s_s_and_s", :unique => true
  add_index "slugs", ["sluggable_id"], :name => "index_slugs_on_sluggable_id"

  create_table "subscriptions", :force => true do |t|
    t.integer  "person_id"
    t.integer  "subscribable_id"
    t.string   "subscribable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subscriptions", ["person_id", "subscribable_type", "subscribable_id"], :name => "unique-subs", :unique => true

  create_table "survey_options", :force => true do |t|
    t.text     "title"
    t.integer  "survey_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.integer  "position"
  end

  create_table "survey_responses", :force => true do |t|
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "survey_id"
  end

  create_table "surveys", :force => true do |t|
    t.integer  "surveyable_id"
    t.string   "surveyable_type"
    t.string   "title"
    t.text     "description"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "max_selected_options",        :default => 0
    t.boolean  "show_progress"
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "end_notification_email_sent"
  end

  create_table "top_items", :force => true do |t|
    t.integer  "item_id"
    t.string   "item_type"
    t.datetime "item_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "conversation_id"
    t.integer  "issue_id"
    t.integer  "person_id"
    t.text     "activity_cache",  :limit => 2147483647
  end

  add_index "top_items", ["conversation_id"], :name => "conversations_index"
  add_index "top_items", ["issue_id"], :name => "issues_index"
  add_index "top_items", ["item_id", "item_type"], :name => "index_top_items_on_item_id_and_item_type"
  add_index "top_items", ["person_id"], :name => "person_index"

  create_table "topics", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "visits", :force => true do |t|
    t.integer  "person_id"
    t.integer  "visitable_id"
    t.string   "visitable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "visits", ["visitable_id", "visitable_type"], :name => "index_visits_on_visitable_id_and_visitable_type"

  create_table "zip_codes", :force => true do |t|
    t.integer  "region_id"
    t.string   "zip_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
