# encoding: utf-8

require_relative 'abstract_query_generator'

module CartoDB
  module InternalGeocoder

    class Admin1ColumnPolygons < AbstractQueryGenerator

      def search_terms_query(page)
        %Q{
          SELECT DISTINCT
            trim(quote_nullable(#{@internal_geocoder.column_name})) as region,
            trim(quote_nullable(#{@internal_geocoder.country_column})) as country
          FROM #{@internal_geocoder.qualified_table_name}
          WHERE cartodb_georef_status IS NULL
          LIMIT #{@internal_geocoder.batch_size} OFFSET #{page * @internal_geocoder.batch_size}
        }
      end

      def dataservices_query(search_terms)
        region = search_terms.map { |row| row[:region] }.join(',')
        countries = search_terms.map { |row| row[:country] }.join(',')
        "WITH geo_function AS (SELECT (geocode_admin1_polygons(Array[#{region}], Array[#{countries}])).*) SELECT q, c, null AS a1, geom, success FROM geo_function"
      end

      def copy_results_to_table_query
        %Q{
          UPDATE #{dest_table}
          SET the_geom = orig.the_geom, cartodb_georef_status = orig.cartodb_georef_status
          FROM #{@internal_geocoder.temp_table_name} AS orig
          WHERE trim(#{dest_table}.#{@internal_geocoder.column_name}::text) = orig.geocode_string
            AND trim(#{dest_table}.#{@internal_geocoder.country_column}::text) = orig.country
            AND #{dest_table}.cartodb_georef_status IS NULL
        }
      end

    end # Admin1ColumnPolygons

  end # InternalGeocoder
end # CartoDB
