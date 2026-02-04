FactoryBot.define do
  factory :interaction_history do
    user { nil }
    admin_user { nil }
    interaction_type { 1 }
    subject { "MyString" }
    description { "MyText" }
    interaction_date { "2026-02-03 15:26:47" }
    follow_up_date { "2026-02-03 15:26:47" }
    status { 1 }
  end
end
