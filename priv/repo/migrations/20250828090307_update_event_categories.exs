defmodule Mobilizon.Storage.Repo.Migrations.UpdateEventCategories do
  use Ecto.Migration

  def up do
    # Mapping old categories to new categories
    category_mappings = %{
      # Arts and culture related
      "ARTS" => "ART_AND_CULTURE",
      "PERFORMING_VISUAL_ARTS" => "ART_AND_CULTURE",
      "THEATRE" => "ART_AND_CULTURE",
      "PHOTOGRAPHY" => "ART_AND_CULTURE",
      "CRAFTS" => "HOBBIES_AND_PASSIONS",
      
      # Business and career
      "BUSINESS" => "CAREER_AND_BUSINESS",
      "NETWORKING" => "CAREER_AND_BUSINESS",
      
      # Community and social
      "COMMUNITY" => "COMMUNITY_AND_ENVIRONMENT",
      "CAUSES" => "COMMUNITY_AND_ENVIRONMENT",
      "SOCIAL_ACTIVITIES" => "SOCIAL_ACTIVITIES",
      "PARTY" => "SOCIAL_ACTIVITIES",
      
      # Education and learning
      "LEARNING" => "SCIENCE_AND_EDUCATION",
      "SCIENCE_TECH" => "SCIENCE_AND_EDUCATION",
      "BOOK_CLUBS" => "SCIENCE_AND_EDUCATION",
      
      # Entertainment
      "GAMES" => "GAMES",
      "COMEDY" => "SOCIAL_ACTIVITIES",
      "MUSIC" => "MUSIC",
      "DANCE" => "DANCE",
      "FILM_MEDIA" => "ART_AND_CULTURE",
      
      # Family and relationships
      "FAMILY_EDUCATION" => "PARENTS_AND_FAMILY",
      
      # Health and wellness
      "HEALTH" => "WELLNESS",
      "SPORTS" => "SPORTS_AND_FITNESS",
      
      # Identity and culture
      "LANGUAGE_CULTURE" => "IDENTITY_AND_LANGUAGE",
      "LGBTQ" => "IDENTITY_AND_LANGUAGE",
      
      # Lifestyle
      "FOOD_DRINK" => "HOBBIES_AND_PASSIONS",
      "FASHION_BEAUTY" => "HOBBIES_AND_PASSIONS",
      "AUTO_BOAT_AIR" => "HOBBIES_AND_PASSIONS",
      
      # Outdoor activities
      "OUTDOORS_ADVENTURE" => "TRAVEL_AND_OUTDOOR",
      
      # Pets and animals
      "PETS" => "PETS_AND_ANIMALS",
      
      # Politics and movements
      "MOVEMENTS_POLITICS" => "MOVEMENT_AND_POLITICS",
      
      # Religion and spirituality
      "SPIRITUALITY_RELIGION_BELIEFS" => "RELIGION_AND_SPIRITUALITY",
      
      # Technology (new category)
      "TECHNOLOGY" => "TECHNOLOGY",
      
      # Writing (new category)
      "WRITING" => "WRITING",
      
      # Default/fallback
      "MEETING" => "SOCIAL_ACTIVITIES"
    }

    # Update events table with new category values
    Enum.each(category_mappings, fn {old_category, new_category} ->
      execute("UPDATE events SET category = '#{new_category}' WHERE category = '#{old_category}'")
    end)

    # Set any unmapped categories to default
    mapped_old_categories = Map.keys(category_mappings)
    old_categories_list = Enum.map(mapped_old_categories, &"'#{&1}'") |> Enum.join(", ")
    
    execute("UPDATE events SET category = 'SOCIAL_ACTIVITIES' WHERE category NOT IN (#{old_categories_list})")
  end

  def down do
    # Reverse mapping - this is best effort since some categories were merged
    reverse_mappings = %{
      "ART_AND_CULTURE" => "ARTS",
      "CAREER_AND_BUSINESS" => "BUSINESS", 
      "COMMUNITY_AND_ENVIRONMENT" => "COMMUNITY",
      "SOCIAL_ACTIVITIES" => "MEETING",
      "SCIENCE_AND_EDUCATION" => "LEARNING",
      "GAMES" => "GAMES",
      "MUSIC" => "MUSIC",
      "DANCE" => "ARTS",
      "PARENTS_AND_FAMILY" => "FAMILY_EDUCATION",
      "WELLNESS" => "HEALTH",
      "SPORTS_AND_FITNESS" => "SPORTS",
      "IDENTITY_AND_LANGUAGE" => "LANGUAGE_CULTURE",
      "HOBBIES_AND_PASSIONS" => "CRAFTS",
      "TRAVEL_AND_OUTDOOR" => "OUTDOORS_ADVENTURE",
      "PETS_AND_ANIMALS" => "PETS",
      "MOVEMENT_AND_POLITICS" => "MOVEMENTS_POLITICS",
      "RELIGION_AND_SPIRITUALITY" => "SPIRITUALITY_RELIGION_BELIEFS",
      "TECHNOLOGY" => "SCIENCE_TECH",
      "WRITING" => "ARTS"
    }

    Enum.each(reverse_mappings, fn {new_category, old_category} ->
      execute("UPDATE events SET category = '#{old_category}' WHERE category = '#{new_category}'")
    end)
  end
end
