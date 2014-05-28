class Movie < ActiveRecord::Base
  define_index do
    indexes :genres
    indexes :subs
    indexes :id
    indexes :imdb_id
  end
  attr_accessible :cast_ids, :cast_names, :cover_url, :full_cover_url, :genres, :imdb_id, :plot, :plot_outline, :rating, :subs, :title, :year
end
