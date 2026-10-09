# Adspirer API — full tool catalog

Every tool below is called with the same envelope:

```
POST https://api.adspirer.ai/api/v1/tools/<tool>/execute
Authorization: Bearer ${ADSPIRER_API_KEY}
Content-Type: application/json

{ "arguments": { ... } }
```

Responses use the standard envelope — `{"success": true, "data": {...}}` on 200, or
`{"success": false, "error": "...", "is_error": true}` on 4xx/5xx (see SKILL.md for
status codes, quota, idempotency, and multi-account rules).

Required arguments are listed per tool; everything else is optional. Multi-account
users must also pass the platform's account ID argument (`customer_id` for Google,
`ad_account_id` for Meta, `advertiser_id` for TikTok, `account_id` for LinkedIn/Amazon)
— omitting it on a multi-account key returns HTTP 400 listing the valid IDs.


## Google Ads ( tools)

| Tool | Required arguments | What it does |
|---|---|---|
| `add_business_name_asset` | `campaign_id`, `business_name` | Add a BUSINESS_NAME asset to a Search campaign. |
| `add_call_asset` | `campaign_id`, `phone_number`, `country_code` | Add a phone call asset to a campaign. |
| `add_callout_extensions` | `campaign_id`, `callouts` | Add callout extensions to a campaign. |
| `add_demandgen_ad_group` | `campaign_id`, `ad_group_name`, `final_url`, `business_name`, `headlines`, `descriptions` | Add a new ad group with targeting and ads to an EXISTING Demand Gen campaign. |
| `add_display_ad` | `ad_group_id`, `final_url`, `business_name`, `headlines`, `long_headline`, `descriptions` | Add another Responsive Display Ad (RDA) to an EXISTING Display ad group. |
| `add_display_ad_group` | `campaign_id`, `ad_group_name`, `final_url`, `business_name`, `headlines`, `long_headline`, `descriptions` | Add a new DISPLAY_STANDARD ad group (with its own targeting + a Responsive Display Ad) to an EXISTING Display campaign. |
| `add_display_audiences` | `ad_group_id`, `audience_segments` | Add audience targeting to a Display ad group. |
| `add_display_keywords` | `ad_group_id`, `display_keywords` | Add contextual display keywords to a Display ad group. |
| `add_display_placements` | `ad_group_id`, `placements` | Add managed placements (websites, mobile apps, YouTube channels, YouTube videos) to a Display ad group. |
| `add_display_topics` | `ad_group_id`, `topics` | Add topic targeting to a Display ad group. |
| `add_keywords` | `ad_group_id`, `keywords` | Add keywords to an existing ad group. |
| `add_negative_keywords` | `campaign_id`, `keywords` | Add negative keywords to a campaign. |
| `add_pmax_asset_group_image` | `campaign_id`, `image_url`, `field_type` | Upload a new image and link it to a PMax asset group. |
| `add_pmax_audience_signal` | `campaign_id` | Add an audience signal to an existing Performance Max campaign. |
| `add_pmax_search_themes` | `campaign_id`, `search_themes` | Add search themes to an existing Performance Max campaign. |
| `add_search_campaign_image` | `campaign_id`, `image_url`, `field_type` | Upload + link an image asset at the SEARCH campaign level. |
| `add_sitelinks` | `campaign_id`, `sitelinks` | Add sitelink extensions to a campaign. |
| `add_structured_snippets` | `campaign_id`, `snippets` | Add structured snippet extensions to a campaign. |
| `analyze_search_terms` | — | Discover keyword opportunities and optimize match types by analyzing actual search terms. |
| `analyze_wasted_spend` | — | Analyze wasted ad spend and identify campaigns losing money or underperforming. |
| `create_ad` | `ad_group_id`, `headlines`, `descriptions`, `final_urls` | Create a new Responsive Search Ad (RSA) in an existing ad group. |
| `create_conversion_action` | `name`, `category` | Create a WEBPAGE conversion action so the account can use TARGET_CPA / MAXIMIZE_CONVERSIONS / TARGET_ROAS bidding. |
| `create_demandgen_campaign` | `campaign_name`, `budget_daily`, `final_url`, `business_name`, `headlines`, `descriptions` | 🔄 LONG-RUNNING TOOL: Creates a Demand Gen campaign across ALL Google channels — YouTube, Discover, Gmail, Display, and Maps. |
| `create_display_campaign` | `campaign_name`, `budget_daily`, `final_url`, `business_name`, `headlines`, `long_headline`, `descriptions` | Create a Google **Display** campaign with a Responsive Display Ad on the Google Display Network (GDN). |
| `create_pmax_campaign` | `campaign_name`, `budget_daily` | 🔄 LONG-RUNNING TOOL: Creates a Google Performance Max campaign with validated images. |
| `create_search_campaign` | `campaign_name`, `business_description`, `website_url`, `budget_daily`, `target_locations`, `ad_groups` | 🔄 LONG-RUNNING TOOL: Creates a Google Ads Search campaign with full structure. |
| `create_youtube_campaign` | `campaign_name`, `budget_daily`, `youtube_video_id`, `final_url`, `business_name`, `headlines`, `descriptions` | 🔄 LONG-RUNNING TOOL: Creates a YouTube Video campaign using Google Ads Demand Gen format with YouTube-only placements. |
| `discover_existing_assets` | — | 🔍 Discover existing assets in the Google Ads account (images, sitelinks, callouts, structured snippets). |
| `explain_performance_anomaly` | `metric`, `period_start`, `period_end` | Explain why a performance metric changed using statistical analysis and historical context. |
| `get_ad_creative` | — | Read/export the creative composition of existing ads — videos, images (downloadable URLs), and all text. |
| `get_ad_performance` | — | Per-AD performance breakdown — one row per ad, with individual metrics. |
| `get_ad_policy_violations` | — | Read policy review/approval state for ads. |
| `get_benchmark_context` | — | Get industry benchmark context for AI-powered recommendations. |
| `get_business_profile` | — | Get the user's business profile for contextual recommendations. |
| `get_campaign_performance` | — | Analyze Google Ads campaign performance with comprehensive insights and recommendations. |
| `get_campaign_structure` | `campaign_id` | Get campaign structure with ad groups, keywords, ads, and extensions. |
| `get_campaign_targeting` | `campaign_id` | Full targeting view for a Google Ads campaign — locations, languages, demographics, audiences, devices, ad schedule, topics, placements, keywords, AND negative variants of each. |
| `get_conversion_action_performance` | — | Per-conversion-action performance breakdown. |
| `get_display_ad_group_settings` | `ad_group_id` | Read every editable setting on a Display ad group. |
| `get_display_audiences` | `campaign_id` | List audience targeting on a Display campaign's ad groups. |
| `get_display_demographics` | `campaign_id` | List demographic targeting (age, gender, parental status, income) on a Display campaign's ad groups. |
| `get_display_frequency_caps` | `campaign_id` | Read the frequency caps currently configured on a Display campaign. |
| `get_display_keywords` | `campaign_id` | List contextual display keywords on a Display campaign's ad groups. |
| `get_display_placements` | `campaign_id` | List all managed placements (websites, mobile apps, YouTube channels, YouTube videos) on a Display campaign's ad groups. |
| `get_display_topics` | `campaign_id` | List topic targeting on a Display campaign's ad groups. |
| `get_pmax_asset_performance` | `campaign_id` | Read Google's own per-asset performance_label for every image in a PMax campaign, plus asset-group-level rollup metrics. |
| `get_pmax_audience_signals` | `campaign_id` | Get current audience signals for a Performance Max campaign. |
| `get_pmax_search_themes` | `campaign_id` | Get current search themes for a Performance Max campaign. |
| `get_usage_status` | — | Get your current usage status with interactive quota widget. |
| `help_user_upload` | — | Show user instructions for uploading images to postimages.org for Performance Max campaigns. |
| `infer_business_profile` | — | Automatically infer business profile from campaign data using AI analysis. |
| `list_campaign_extensions` | `campaign_id` | List all extensions (sitelinks, callouts, structured snippets) for a campaign. |
| `list_campaigns` | — | List all Google Ads campaigns for the connected account. |
| `list_conversion_actions` | — | List conversion actions for the connected Google Ads account with full per-action metadata. |
| `list_google_languages` | — | List Google Ads language constants. |
| `list_pmax_asset_group_images` | `campaign_id` | List image assets linked to Performance Max asset groups, grouped by asset_group_id. |
| `optimize_budget_allocation` | `total_budget` | Optimize budget allocation across campaigns using linear programming to maximize conversions. |
| `pause_ad` | `ad_id`, `ad_group_id` | Pause an ad to stop it from showing. |
| `pause_ad_group` | `ad_group_id` | Pause an ad group so none of its ads serve. |
| `pause_campaign` | `campaign_id` | Quickly pause a running campaign. |
| `remove_callouts` | `campaign_id` | Remove callout extensions from a campaign. |
| `remove_display_ad` | `ad_group_id`, `ad_id` | Remove (soft-delete) a Responsive Display Ad. |
| `remove_display_ad_group` | `ad_group_id` | Remove (soft-delete) a Display ad group. |
| `remove_display_criteria` | `criterion_resource_names` | Remove one or more AdGroupCriteria from a Display ad group by resource name. |
| `remove_keywords` | `ad_group_id`, `keyword_ids` | Remove keywords from an ad group. |
| `remove_negative_keywords` | `campaign_id`, `keyword_ids` | Remove negative keywords from a campaign. |
| `remove_pmax_asset_group_image` | `campaign_id` | Unlink an image from a PMax asset group. |
| `remove_pmax_audience_signal` | `campaign_id`, `signal_resource_name` | Remove a specific audience signal from a Performance Max campaign. |
| `remove_pmax_search_themes` | `campaign_id`, `themes_to_remove` | Remove specific search themes from a Performance Max campaign. |
| `remove_sitelinks` | `campaign_id` | Remove sitelink extensions from a campaign. |
| `remove_structured_snippets` | `campaign_id` | Remove structured snippet extensions from a campaign. |
| `research_keywords` | — | Research high-intent keywords using Google Keyword Planner API. |
| `resolve_google_locations` | `queries` | Resolve free-text location queries (country, state/province, city, district, postal code) into Google's exact `geoTargetConstants/<id>` resource names. |
| `resume_ad` | `ad_id`, `ad_group_id` | Resume a paused ad to start showing it again. |
| `resume_ad_group` | `ad_group_id` | Resume a paused ad group (any channel). |
| `resume_campaign` | `campaign_id` | Resume a paused campaign. |
| `save_business_profile` | `business_vertical`, `business_size`, `primary_goal` | Save or update the user's business profile with provided details. |
| `search_audiences` | `query` | Search for available audience segments (in-market, affinity, custom). |
| `select_google_campaign_type` | `campaign_type` | This tool guides the user to select their campaign TYPE, then returns a step-by-step workflow with which tools to call next. |
| `suggest_ad_content` | `campaign_id` | Generate AI-suggested headlines and descriptions based on campaign keywords. |
| `update_ad_content` | `ad_id`, `ad_group_id` | Combined update for ad content (RSA or RDA) in a single API call with combined field mask. |
| `update_ad_descriptions` | `ad_id`, `ad_group_id`, `descriptions` | Update descriptions for a Responsive Search Ad (RSA) OR Responsive Display Ad (RDA). |
| `update_ad_headlines` | `ad_id`, `ad_group_id`, `headlines` | Update headlines for a Responsive Search Ad (RSA) OR Responsive Display Ad (RDA). |
| `update_bid_strategy` | `campaign_id`, `strategy` | Change campaign bidding strategy. |
| `update_campaign` | `campaign_id` | Update an existing campaign's settings. |
| `update_display_ad_creative` | `ad_group_id`, `ad_id` | Edit any combination of CREATIVE fields on a Responsive Display Ad. |
| `update_display_ad_group` | `ad_group_id` | Update one or more editable settings on a Display ad group in a single API call. |
| `update_display_campaign_schedule` | `campaign_id` | Update a Display campaign's start_date and/or end_date. |
| `update_display_demographics` | `ad_group_id`, `demographics` | Update demographic targeting on a Display ad group via the exclude-the-inverse pattern. |
| `update_display_frequency_caps` | `campaign_id`, `frequency_caps` | REPLACE all frequency caps on a Display campaign. |
| `update_keyword` | `keyword_id`, `ad_group_id` | Update keyword bid or status. |
| `update_location_targeting` | `campaign_id`, `positive_geo_target_type` | Change a campaign's location-targeting MODE without recreating the campaign. |
| `update_pmax_audience_signal` | `audience_resource_name` | Update the segment composition of an existing PMax audience IN PLACE (#325). |
| `validate_and_prepare_assets` | `marketing_images_landscape`, `marketing_images_square`, `logos_square` | 🔄 LONG-RUNNING TOOL — **GOOGLE ADS ONLY**. |
| `validate_video` | `video_url_or_id`, `platform` | Validate video for ad campaigns (unified tool for all platforms). |

## Meta Ads (Facebook & Instagram) ( tools)

| Tool | Required arguments | What it does |
|---|---|---|
| `add_meta_ad` | `ad_set_id`, `ad_type`, `landing_page_url` | User wants to add another ad/creative variation to an EXISTING ad set. |
| `add_meta_ad_set` | `campaign_id`, `ad_type`, `primary_text`, `landing_page_url` | User wants to add a new ad set to an EXISTING campaign. |
| `analyze_meta_ad_performance` | — | User wants detailed analysis of specific Meta ads, creative performance, or wants to identify winning/losing ad variations. |
| `analyze_meta_audiences` | — | User asks about Meta/Facebook/Instagram audience performance by demographics, age group or gender targeting optimization, audience saturation, or which demographic segments to target or exclude. |
| `analyze_meta_wasted_spend` | — | User asks about Meta/Facebook/Instagram ad spend efficiency, wasted money, underperforming campaigns, placement optimization, or creative fatigue. |
| `browse_meta_targeting` | `category` | User wants to browse all targeting options in a specific category without a search query. |
| `create_meta_carousel_campaign` | `campaign_name`, `primary_text`, `cards` | User wants to create a Meta (Facebook/Instagram) carousel ad campaign with multiple images. |
| `create_meta_dco_ad` | `ad_set_id`, `image_urls`, `primary_text`, `landing_page_url` | User wants Meta to automatically TEST MULTIPLE IMAGES and find the best combination. |
| `create_meta_image_campaign` | `campaign_name`, `landing_page_url` | User wants to create a Meta (Facebook/Instagram) single-image ad campaign. |
| `create_meta_video_campaign` | `campaign_name`, `landing_page_url` | User wants to create a Meta (Facebook/Instagram) video ad campaign. |
| `detect_meta_creative_fatigue` | — | User asks about creative fatigue, ad refresh timing, frequency management, declining CTR, when to replace ads, or audience exhaustion on Meta/Facebook/Instagram. |
| `discover_meta_assets` | — | User wants to browse existing images and videos in their Meta Ad Library for reuse in new campaigns. |
| `duplicate_meta_campaign` | `campaign_id` | User wants to duplicate/copy an existing Meta campaign with all its ad sets, ads, and settings. |
| `explain_meta_anomaly` | — | User asks why Meta/Facebook/Instagram performance dropped or changed, what happened to their ROAS/CTR/CPM, or wants to understand why a metric changed during a specific period. |
| `get_meta_ad_creatives` | — | User wants to see their Meta ad creatives, ad copy, media URLs, or creative performance. |
| `get_meta_adset_performance` | — | User wants ad-set-level Meta performance — the middle layer between campaigns and individual ads. |
| `get_meta_audience_insights` | — | User asks about audience demographics, which placements perform best, device breakdown, or targeting optimization for Meta ads. |
| `get_meta_campaign_details` | `campaign_id` | User wants to see detailed information about a specific Meta campaign, including its full structure (ad sets, ads, targeting, budgets). |
| `get_meta_campaign_performance` | — | User asks about Meta/Facebook/Instagram ad performance, campaign metrics, ROAS, spend analysis, or wants to understand how their Meta ads are performing. |
| `get_meta_lead_form_submissions` | `form_id` | User wants to see lead submissions, lead data, or leads collected from a Meta lead form. |
| `list_meta_ad_sets` | — | User wants to see the ad sets within a specific Meta campaign, including their targeting, budgets, and optimization settings. |
| `list_meta_ads` | — | User wants to see the individual ads within a specific Meta ad set, including their status and creative information. |
| `list_meta_campaigns` | — | User wants to see their existing Meta/Facebook/Instagram campaigns, browse campaign structure, or find a campaign ID. |
| `list_meta_custom_audiences` | — | User wants to browse, list, or select Custom Audiences for targeting — DB lists, lookalike audiences, remarketing segments, website visitors, engagement audiences. |
| `list_meta_instagram_accounts` | — | User wants to run ads on Instagram, asks about Instagram accounts, or you need to find the instagram_account_id before campaign creation. |
| `list_meta_lead_forms` | — | User wants to see their Meta lead generation forms, list lead forms, or find a lead form ID. |
| `list_meta_pixels` | — | User wants conversion tracking, asks about Meta Pixels, or before creating OUTCOME_SALES campaigns. |
| `optimize_meta_budget` | `total_budget` | User asks about Meta/Facebook/Instagram budget optimization, reallocating ad spend, maximizing conversions with their budget, or wants data-driven budget recommendations. |
| `optimize_meta_placements` | — | User asks about Meta/Facebook/Instagram placement performance, which placements work best, Feed vs Stories vs Reels, should they use Audience Network, or wants placement optimization recommendations. |
| `pause_meta_campaign` | `campaign_id` | User wants to pause a running Meta campaign. |
| `resume_meta_campaign` | `campaign_id` | User wants to resume a paused Meta campaign. |
| `search_meta_targeting` | `search_type`, `query` | User wants to find targeting options for their Meta (Facebook/Instagram) ad campaigns. |
| `select_meta_campaign_type` | `campaign_type` | User wants to create a Meta (Facebook/Instagram) ad campaign but hasn't specified the campaign type (image, video, carousel, or app). |
| `update_meta_ad` | `ad_id` | User wants to update an individual Meta ad — pause/resume it, rename it, or swap its creative. |
| `update_meta_ad_set` | `ad_set_id` | User wants to edit an existing Meta ad set's targeting, budget, bid, placements, schedule, or optimization settings. |
| `update_meta_campaign` | `campaign_id` | User wants to update an existing Meta campaign's status, budget, name, or schedule. |
| `validate_and_prepare_meta_assets` | `image_urls` | because image specs differ: |

## LinkedIn Ads ( tools)

| Tool | Required arguments | What it does |
|---|---|---|
| `add_linkedin_campaign_to_group` | `campaign_group_id`, `campaign_name`, `daily_budget`, `organization_id`, `ad_type`, `landing_page_url`, `locations` | LinkedIn hierarchy: Campaign Group → Campaign → Creative. |
| `add_linkedin_carousel_creative` | `campaign_id`, `organization_id`, `cards`, `introductory_text`, `landing_page_url` | User wants to add another carousel ad variation to an existing carousel campaign. |
| `add_linkedin_creative` | `campaign_id`, `organization_id`, `image_urn`, `introductory_text`, `landing_page_url` | → Use `add_linkedin_campaign_to_group` instead (creates a new campaign in the same group). |
| `add_linkedin_text_creative` | `campaign_id`, `headline`, `description`, `landing_page_url` | LinkedIn recommends 3-4 text ad variations per campaign. |
| `add_linkedin_video_creative` | `campaign_id`, `organization_id`, `video_urn`, `introductory_text`, `landing_page_url` | LinkedIn recommends 3-4 video ad variations per campaign. |
| `analyze_linkedin_creative_performance` | — | User asks about ad/creative performance, |
| `analyze_linkedin_wasted_spend` | — | User asks about wasted ad spend, unprofitable campaigns, |
| `associate_linkedin_conversion` | `campaign_id`, `conversion_id` | User wants to add conversion tracking to a campaign. |
| `batch_update_linkedin_campaigns` | `campaign_ids` | User wants to update multiple LinkedIn campaigns at once (bulk operations). |
| `clone_linkedin_campaign` | `source_campaign_id` | User wants to duplicate, copy, or clone a LinkedIn campaign. |
| `create_linkedin_carousel_campaign` | `campaign_name`, `daily_budget`, `organization_id`, `cards`, `introductory_text`, `landing_page_url`, `locations` | IMPORTANT: This creates the campaign with 1 creative (Variation 1). |
| `create_linkedin_image_campaign` | `campaign_name`, `daily_budget`, `organization_id`, `introductory_text`, `headline`, `landing_page_url`, `locations` | This tool creates REAL LinkedIn campaigns that cost REAL money. |
| `create_linkedin_text_campaign` | `campaign_name`, `daily_budget`, `organization_id`, `headline`, `description`, `landing_page_url`, `locations` | IMPORTANT: This creates the campaign with 1 creative (Variation 1). |
| `create_linkedin_video_campaign` | `campaign_name`, `daily_budget`, `organization_id`, `introductory_text`, `headline`, `landing_page_url`, `locations` | IMPORTANT: This creates the campaign with 1 creative (Variation 1). |
| `delete_linkedin_creative` | `creative_id` | User wants to delete, archive, or remove a LinkedIn ad/creative. |
| `discover_linkedin_assets` | `organization_id` | User wants to find existing images/videos in their LinkedIn account to reuse. |
| `explain_linkedin_anomaly` | — | User asks why their LinkedIn metrics changed, |
| `explain_linkedin_objectives` | — | User asks about LinkedIn campaign objectives or which one to choose. |
| `generate_linkedin_ad_creatives` | `business_name`, `business_description`, `target_audience`, `value_proposition`, `landing_page_url` | User needs ad copy for LinkedIn campaigns. |
| `get_linkedin_audience_insights` | — | User asks about B2B audience demographics, |
| `get_linkedin_campaign_performance` | — | User asks about LinkedIn Ads performance, campaign metrics, |
| `get_linkedin_campaign_structure` | `campaign_id` | User wants full details about a specific LinkedIn campaign. |
| `get_linkedin_campaign_targeting` | `campaign_id` | User wants to copy targeting from one campaign to another. |
| `get_linkedin_engagement_metrics` | — | User asks specifically about LinkedIn engagement, |
| `get_linkedin_organizations` | — | Fetch the LinkedIn Organizations (Company Pages) AND Ad Accounts the user can manage. |
| `list_linkedin_campaign_groups` | — | User wants to see their LinkedIn campaign groups (also called campaign folders or groups). |
| `list_linkedin_campaigns` | — | User wants to see all their LinkedIn campaigns with performance metrics. |
| `list_linkedin_conversions` | — | User wants to see available conversion tracking options. |
| `list_linkedin_creatives` | `campaign_id` | User wants to see all ads in a LinkedIn campaign. |
| `manage_linkedin_conversions` | `action` | User wants to manage LinkedIn conversion tracking - list, create, associate conversions, or set up full conversion tracking. |
| `optimize_linkedin_budget` | `total_budget` | User asks how to allocate their LinkedIn budget, |
| `pause_linkedin_campaign` | `campaign_id` | User wants to pause an active LinkedIn campaign. |
| `pause_linkedin_creative` | `creative_id` | User wants to pause a specific ad within a campaign. |
| `research_business_for_linkedin_targeting` | `website_url` | User wants targeting recommendations based on their business. |
| `resume_linkedin_campaign` | `campaign_id` | User wants to resume a paused LinkedIn campaign. |
| `resume_linkedin_creative` | `creative_id` | User wants to resume a paused ad. |
| `search_linkedin_targeting` | `facet_type`, `query` | User needs to find targeting URNs for LinkedIn campaigns. |
| `select_linkedin_campaign_type` | `campaign_type` | User wants to create a LinkedIn ad campaign but hasn't specified the campaign type (image, video, carousel, or text). |
| `update_linkedin_campaign` | `campaign_id` | User wants to modify LinkedIn campaign settings. |
| `update_linkedin_campaign_budget` | `campaign_id` | User wants to change a LinkedIn campaign's budget (daily or total). |
| `update_linkedin_campaign_group` | `campaign_group_id` | User wants to modify a LinkedIn campaign group (rename, change status, update budget). |
| `update_linkedin_campaign_schedule` | `campaign_id`, `end_date` | User wants to change a LinkedIn campaign's end date or schedule. |
| `update_linkedin_campaign_targeting` | `campaign_id` | User wants to add or remove targeting criteria from a LinkedIn campaign. |
| `update_linkedin_creative` | `creative_id`, `campaign_id` | User wants to edit a LinkedIn ad/creative. |
| `validate_and_prepare_linkedin_assets` | `image_urls` | because image specs differ: |

## TikTok Ads ( tools)

| Tool | Required arguments | What it does |
|---|---|---|
| `add_tiktok_ad` | `adgroup_id`, `ad_text`, `landing_page_url` | Add a new ad to an existing TikTok ad group. |
| `add_tiktok_ad_group` | `campaign_id`, `adgroup_name`, `budget` | Add a new ad group to an existing TikTok campaign. |
| `analyze_tiktok_geo_performance` | — | Analyze TikTok geographic/country-level performance. |
| `analyze_tiktok_wasted_spend` | — | Analyze TikTok campaigns for wasted ad spend. |
| `create_tiktok_campaign` | `campaign_name`, `ad_text`, `display_name`, `landing_page_url` | User wants to create a TikTok ad campaign with IMAGES, Spark Ads, or Carousel ads (not video). |
| `create_tiktok_carousel_card` | `image_ids` | Create a carousel card from multiple images for TikTok carousel ads. |
| `create_tiktok_video_campaign` | `campaign_name`, `ad_text`, `landing_page_url` | User wants to create a TikTok ad campaign with a VIDEO (not images). |
| `delete_tiktok_ad` | `ad_id` | Delete a TikTok ad [write] |
| `delete_tiktok_ad_group` | `adgroup_id` | Delete a TikTok ad group (cascades to child ads). |
| `delete_tiktok_campaign` | `campaign_id` | Delete a TikTok campaign (DELETE status — cascades to all child ad groups and ads). |
| `detect_tiktok_creative_fatigue` | — | Detect TikTok creative fatigue using video-specific metrics (hook rate decline, completion rate decline, engagement decline, frequency). |
| `discover_tiktok_assets` | — | User wants to reuse existing TikTok images instead of uploading new ones. |
| `explain_tiktok_anomaly` | `period_start`, `period_end` | Explain why a TikTok metric changed during a specific period. |
| `explain_tiktok_objective` | `objective_type` | Explain what a TikTok campaign objective requires BEFORE attempting to create one. |
| `get_tiktok_ad_group_details` | `adgroup_id` | Get full details for a single TikTok ad group: targeting, placements, pixel/optimization event, schedule, and timestamps. |
| `get_tiktok_ad_performance` | — | Get TikTok ad-level performance with creative details, video metrics, and engagement. |
| `get_tiktok_audience_insights` | — | Analyze TikTok audience segment performance by age, gender, and combined demographics. |
| `get_tiktok_campaign_details` | `campaign_id` | Get detailed information about a specific TikTok campaign including status, budget, objective, and timestamps. |
| `get_tiktok_campaign_performance` | — | Get TikTok campaign performance metrics including TikTok-specific video and engagement data. |
| `list_tiktok_ad_groups` | — | List TikTok ad groups. |
| `list_tiktok_ads` | — | List tiktok ads. |
| `list_tiktok_campaigns` | — | List all TikTok campaigns with their status, objective, and budget. |
| `list_tiktok_custom_audiences` | — | List DMP custom audiences on the advertiser (customer-list, pixel-event, lookalike audiences). |
| `list_tiktok_identities` | — | List every TikTok identity available on the advertiser (BC_AUTH_TT, TT_USER, etc.). |
| `list_tiktok_saved_audiences` | — | List saved (re-usable demographic + interest) audiences. |
| `optimize_tiktok_budget` | `total_budget` | Optimize TikTok budget allocation using linear programming to maximize conversions. |
| `pause_tiktok_ad` | `ad_id` | Pause a TikTok ad [write] |
| `pause_tiktok_ad_group` | `adgroup_id` | Pause a TikTok ad group. |
| `pause_tiktok_campaign` | `campaign_id` | Pause a TikTok campaign. |
| `resume_tiktok_ad` | `ad_id` | Resume a paused TikTok ad. |
| `resume_tiktok_ad_group` | `adgroup_id` | Resume a paused TikTok ad group. |
| `resume_tiktok_campaign` | `campaign_id` | Resume a paused TikTok campaign. |
| `search_tiktok_targeting` | `targeting_type` | Search TikTok targeting options for campaign creation and ad group management. |
| `update_tiktok_ad_group` | `adgroup_id` | Update TikTok ad group settings: name, budget, targeting (age, gender, locations), schedule. |
| `update_tiktok_campaign` | `campaign_id` | Update TikTok campaign settings like name, budget, or budget mode. |
| `upload_tiktok_images` | `image_urls` | Upload images to TikTok Asset Library from public URLs. |
| `validate_and_prepare_tiktok_assets` | `image_urls` | because image specs differ: |

## Amazon Ads ( tools)

| Tool | Required arguments | What it does |
|---|---|---|
| `add_amazon_keywords` | `keywords` | Add keywords to a MANUAL SP ad group. |
| `add_amazon_negative_keywords` | `negative_keywords` | Block wasteful search terms. |
| `add_amazon_product_ads` | `product_ads` | Add products (ASINs for vendors, SKUs for sellers) to an existing SP ad group. |
| `add_amazon_sb_keywords` | `keywords` | Add keywords to an SB ad group. |
| `add_amazon_sb_negative_keywords` | `negative_keywords` | Block search terms on SB campaigns. |
| `add_amazon_sb_targets` | `targets` | SB product targeting — 'expressions' PLURAL with camelCase types (asinSameAs, asinCategorySameAs, asinBrandSameAs) — differs from SP. |
| `add_amazon_sb_themes` | `themes` | Theme-based SB targeting (KEYWORDS_RELATED_TO_YOUR_BRAND / ..._LANDING_PAGES) — Amazon auto-matches related queries. |
| `add_amazon_targets` | `targets` | Target specific ASINs or categories. |
| `amazon_unified_api` | `resource`, `verb` | POWER TOOL — direct access to Amazon's modern unified Ads API (/adsApi/v1 create/query/update/delete on campaigns/adGroups/ads/targets across ALL ad products). |
| `analyze_amazon_placements` | — | Placement breakdown (top-of-search vs product pages vs rest-of-search) with ACOS per placement and a placement-bid-adjustment recommendation. |
| `analyze_amazon_targeting` | — | Per-keyword/target efficiency with current bids and a bid up/down/negative suggestion per target — the keyword-level optimization loop. |
| `analyze_amazon_wasted_spend` | — | Find search terms burning spend with ZERO sales, totaled and ranked — with a ready negative-keyword action plan. |
| `create_amazon_ad_groups` | `ad_groups` | Create Sponsored Products ad groups in existing campaigns. |
| `create_amazon_sb_ad` | `ad_type`, `ads` | Create Sponsored Brands ads of ANY type: productCollection (logo+headline+3 ASINs), video, brandVideo, storeSpotlight (store subpages), autoCollection, manualCollection, productCollectionExtended. |
| `create_amazon_sb_campaign` | `name`, `budget` | Create a Sponsored Brands campaign (brand banner with logo + headline + ≥3 products). |
| `create_amazon_sd_campaign` | `name`, `daily_budget` | Create a Sponsored Display campaign (display/remarketing ads on and off Amazon) with optional ad group. |
| `create_amazon_sp_campaign` | `name`, `daily_budget` | Create a complete Sponsored Products campaign: campaign → ad group → product ads (your ASINs/SKUs) → keywords (MANUAL only). |
| `delete_amazon_ad_groups` | `ad_group_ids` | Delete (archive) SP ad groups. |
| `delete_amazon_campaigns` | `campaign_ids` | Delete (archive) Amazon Ads campaigns. |
| `delete_amazon_keywords` | `keyword_ids` | Delete (archive) SP keywords. |
| `delete_amazon_negative_keywords` | `keyword_ids` | Remove negative keywords (un-block terms). |
| `delete_amazon_product_ads` | `ad_ids` | Delete (archive) SP product ads. |
| `delete_amazon_sb_keywords` | `keyword_ids` | Archive SB keywords [write] |
| `delete_amazon_targets` | `target_ids` | Delete (archive) SP targeting clauses. |
| `get_amazon_bid_recommendations` | `campaign_id`, `ad_group_id`, `targeting_expressions` | Theme-based suggested bids for targeting expressions in an ad group (AUTO themes or specific keywords). |
| `get_amazon_budget_recommendations` | `campaign_ids` | Amazon-recommended daily budgets + estimated missed impressions/clicks/sales for under-budgeted campaigns. |
| `get_amazon_budget_usage` | `campaign_ids` | Percent of daily budget already consumed per campaign — find campaigns capping out. |
| `get_amazon_campaign_performance` | — | Amazon Ads performance report (Reporting v3): impressions, clicks, CTR, spend, purchases, sales, ACOS, ROAS — totals plus per-campaign breakdown. |
| `get_amazon_keyword_recommendations` | — | Amazon-suggested keywords with theme metrics. |
| `get_amazon_product_performance` | — | Per-ASIN/SKU ad performance — which advertised products convert and which burn spend. |
| `get_amazon_purchased_products` | — | Cross-sell intelligence: what shoppers ACTUALLY bought after clicking your ads (incl. |
| `get_amazon_report` | `report_id` | Fetch a previously-requested Amazon report by report_id. |
| `get_amazon_sb_bid_recommendations` | `campaign_id`, `targets` | Suggested bids for SB targeting expressions. |
| `get_amazon_sb_keyword_recommendations` | — | SB keyword suggestions by creative ASINs or store/landing-page URL. |
| `get_amazon_search_terms` | — | Search-term report: the actual shopper queries that triggered SP ads, with spend/sales per term. |
| `list_amazon_ad_groups` | — | List Sponsored Products ad groups, optionally filtered to campaigns. |
| `list_amazon_campaigns` | — | List Amazon Ads campaigns — Sponsored Products and/or Sponsored Brands — with state, budget and targeting type. |
| `list_amazon_keywords` | — | List SP keywords with bids and match types, optionally by campaign. |
| `list_amazon_negative_keywords` | — | List SP negative keywords. |
| `list_amazon_product_ads` | — | List SP product ads (the advertised ASINs/SKUs), optionally by campaign. |
| `list_amazon_profiles` | — | List the user's Amazon Ads advertiser profiles (accounts). |
| `list_amazon_sb_ad_groups` | — | List Sponsored Brands ad groups. |
| `list_amazon_sb_ads` | — | List Sponsored Brands ads (creatives). |
| `list_amazon_sb_creatives` | — | List creative versions for SB ads (incl. |
| `list_amazon_sb_keywords` | — | List Sponsored Brands keywords. |
| `list_amazon_sb_targets` | — | List SB product/category targeting clauses. |
| `list_amazon_targets` | — | List SP product/category targeting clauses. |
| `optimize_amazon_budget` | — | Budget reallocation plan: per-campaign ACOS crossed with real-time budget usage — identifies efficient campaigns capping out (scale UP) and inefficient spenders (scale DOWN), with concrete next actions. |
| `pause_amazon_campaigns` | `campaign_ids` | Pause one or more Amazon Ads campaigns (SP or SB). |
| `resume_amazon_campaigns` | `campaign_ids` | Resume (enable) paused Amazon Ads campaigns (SP or SB). |
| `search_amazon_assets` | — | Browse existing creative assets (brand logos, images, videos) to reuse their asset IDs. |
| `update_amazon_ad_groups` | `ad_groups` | Update SP ad groups (name, state, defaultBid). |
| `update_amazon_campaigns` | `campaigns` | Update campaign fields: budget, name, end date, bidding. |
| `update_amazon_keywords` | `keywords` | Update SP keyword bids and/or state. |
| `update_amazon_product_ads` | `product_ads` | Update SP product ads (pause/enable individual products). |
| `update_amazon_sb_ads` | `ads` | Pause/enable Sponsored Brands ads. |
| `update_amazon_sb_creative` | `ad_type`, `creatives` | Submit a NEW creative version for an existing SB ad (creative refresh — goes through Amazon moderation). |
| `update_amazon_sb_keywords` | `keywords` | Update SB keyword bids/state (lowercase states: enabled/paused). |
| `update_amazon_sb_targets` | `targets` | Update SB target bids/state. |
| `update_amazon_targets` | `targets` | Update SP targeting clause bids/state. |
| `upload_amazon_asset` | `asset_url`, `name` | Download an image/video from a URL, validate it against Amazon's creative specs (BRAND_LOGO ≥400×400px ≤1MB; OTHER_IMAGE ≥1200×628px ≤5MB; BACKGROUND_VIDEO MP4/MOV), and upload+register it in the creative asset library. |

## ChatGPT Ads ( tools)

| Tool | Required arguments | What it does |
|---|---|---|
| `archive_chatgpt_ad` | `ad_id` | Archive (delete) a single ChatGPT ad. |
| `archive_chatgpt_ad_group` | `ad_group_id` | Archive (delete) a ChatGPT Ads ad group. |
| `archive_chatgpt_campaign` | `campaign_id` | Archive (delete) a ChatGPT Ads campaign. |
| `chatgpt_geo_lookup` | `query` | Resolve a location name (e.g. |
| `create_chatgpt_ad` | `ad_group_id`, `title`, `body`, `target_url` | Create a chat_card ad under an existing ad group. |
| `create_chatgpt_ad_group` | `campaign_id`, `name` | Create an ad group under an existing campaign. |
| `create_chatgpt_campaign` | `name` | Create a campaign by itself (no ad group/ad). |
| `get_chatgpt_ad` | `ad_id` | Get full detail for one ChatGPT ad, including review status and reason. |
| `get_chatgpt_ad_group` | `ad_group_id` | Get full detail for one ChatGPT Ads ad group. |
| `get_chatgpt_campaign` | `campaign_id` | Get full detail for one ChatGPT Ads campaign. |
| `get_chatgpt_conversions_config` | — | Show the brand's ChatGPT Ads conversion-tracking config (Pixel ID, whether a Conversions API key is set, enabled flag, and the ready-to-paste pixel snippet). |
| `get_chatgpt_insights` | — | Full performance reporting at any scope: ad_account, campaign, ad_group, or ad (pass scope + scope_id). |
| `get_chatgpt_performance` | — | Performance for ChatGPT Ads: impressions, clicks, spend, CTR, CPC — by campaign over a lookback window, optionally broken out daily or monthly. |
| `launch_chatgpt_ad` | `name`, `headline`, `body`, `image_url`, `target_url` | Create a complete ChatGPT ad in one step: campaign → ad group → image upload → chat_card ad. |
| `list_chatgpt_accounts` | — | Show the connected ChatGPT Ads (OpenAI Ads) account. |
| `list_chatgpt_ad_groups` | `campaign_id` | List ad groups under a ChatGPT Ads campaign. |
| `list_chatgpt_ads` | `ad_group_id` | List the ads (chat_cards) in a ChatGPT Ads ad group, with review status. |
| `list_chatgpt_campaigns` | — | List ChatGPT Ads campaigns with status, daily budget, and review status. |
| `list_chatgpt_conversion_events` | — | List the supported ChatGPT Ads conversion event types and their data shapes. |
| `pause_chatgpt_ad` | `ad_id` | Pause a single ChatGPT ad. |
| `pause_chatgpt_ad_group` | `ad_group_id` | Pause a ChatGPT Ads ad group. |
| `pause_chatgpt_campaign` | `campaign_id` | Pause a ChatGPT Ads campaign (stops delivery; resume any time). |
| `resume_chatgpt_ad` | `ad_id` | Activate a single ChatGPT ad. |
| `resume_chatgpt_ad_group` | `ad_group_id` | Activate a ChatGPT Ads ad group. |
| `resume_chatgpt_campaign` | `campaign_id` | Activate (resume) a ChatGPT Ads campaign — this is the spend gate; delivery starts. |
| `set_chatgpt_conversions_config` | — | Save the brand's Pixel ID and/or Conversions API key (stored encrypted), and enable/disable conversion tracking. |
| `test_chatgpt_conversion` | — | Send a validate-only test conversion event through the Conversions API to verify setup (requires a Pixel ID + Conversions API key already configured). |
| `update_chatgpt_ad` | `ad_id` | Update an ad's creative (title, body, target_url), name, and/or status. |
| `update_chatgpt_ad_group` | `ad_group_id` | Update an ad group's name, max_bid, status, and/or context_hints. |
| `update_chatgpt_campaign` | `campaign_id` | Update a campaign's daily budget, name, and/or status. |
| `upload_chatgpt_creative` | `image_url` | Upload a PUBLIC image URL (square PNG/JPG ≥256px) and get a file_id to use in create_chatgpt_ad. |

## Monitoring & Reporting ( tools)

| Tool | Required arguments | What it does |
|---|---|---|
| `apply_signal_actions` | `signal_id` | Apply the pre-staged fixes for a signal (executes on the ad platform). |
| `create_monitor` | `metric`, `operator`, `threshold` | Create a monitoring alert for the user's ad campaigns. |
| `delete_monitor` | `task_id` | Delete a monitoring alert by its task ID. |
| `generate_report_now` | — | Generate an immediate performance report and deliver it now. |
| `get_monitor_history` | `alert_id` | Show trigger history for a monitoring alert. |
| `get_research_status` | `job_id` | Check the status of a research job. |
| `get_signal_briefing` | `signal_id` | Open a watch-signal briefing (use this when an Adspirer alert email asks you to). |
| `list_monitors` | — | List all your monitoring alerts. |
| `list_pending_actions` | — | List auto-actions waiting for your approval. |
| `list_scheduled_tasks` | — | List all your scheduled automation tasks. |
| `manage_action` | `action_id`, `decision` | Approve or reject a pending auto-action. |
| `manage_scheduled_task` | `task_id`, `action` | Manage a scheduled task — pause, resume, or delete. |
| `run_watch_now` | — | Run the Watch Agent now — an on-demand proactive scan of your ad accounts. |
| `schedule_brief` | `name`, `delivery_destination` | Schedule recurring performance briefs delivered to your inbox. |
| `start_research` | `research_type`, `context` | Start an AI-powered research job (runs in background). |
| `test_monitor` | `alert_id` | Dry-run a monitor against current data WITHOUT triggering alerts or sending notifications. |

## General, Diagnostics & Integrations ( tools)

| Tool | Required arguments | What it does |
|---|---|---|
| `audit_conversion_tracking` | — | Review your conversion tracking setup across ad platforms. |
| `diagnose_my_setup` | — | Full account + connection health check: MCP auth (AI-client→Adspirer), ad-platform OAuth tokens, and per-platform health. |
| `explain_platform_error` | `error` | Translate an opaque ad-platform error message into a plain-language cause and the exact next step to fix it. |
| `get_campaign_spec` | `platform` | Get the exact required fields, character limits, asset requirements, and enums for a campaign type on a platform. |
| `get_connections_status` | — | View connected ad accounts and OAuth connections. |
| `google_analytics` | `action` | Read Google Analytics 4 reports and metadata for the user's connected GA4 properties. |
| `klaviyo` | `action` | Read and act on the user's Klaviyo (email + SMS marketing) account. |
| `list_connected_accounts` | — | List all connected ad accounts across platforms. |
| `list_what_i_can_do` | — | Personalized capability menu — directly answers 'can it even do X?'. |
| `preflight_campaign` | `platform` | Check an ad account is launch-ready BEFORE creating a campaign: billing active, notification email, platform connected, account access, and (Meta) Facebook Page + pixel. |
| `start_here` | — | Personalized starting point for THIS user. |
| `suggest_next_action` | — | Rank the highest-value next things this user can do RIGHT NOW given their connected data — analyze/report on existing... |
| `switch_primary_account` | `platform` | Activate ad accounts for a platform. |
| `usage_value_summary` | — | Frame the user's plan as value delivered: tool calls used vs included this period and what those calls accomplished. |
| `validate_campaign_draft` | `platform`, `campaign_type`, `draft` | Dry-run validate a fully-assembled campaign draft against the platform spec (no platform write). |
| `verify_campaign_is_live` | `platform`, `campaign_id` | After creating a campaign, confirm it actually exists and is serving (not paused / $0 budget). |
| `weekly_opportunities` | — | Surface 1-3 concrete, high-value optimization opportunities from the user's recent performance (wasted spend, paused-but-spent campaigns, active-but-not-delivering). |
| `whats_changed_since_last_visit` | — | Show the user how long they've been away and what moved in their ad accounts since (spend/clicks/conversions trend + biggest-mover campaigns). |
| `why_did_this_fail` | — | Summarize the user's recent failed tool calls and the errors, so you can correct and retry. |
