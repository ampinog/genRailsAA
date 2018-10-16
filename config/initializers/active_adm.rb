# initializers/active_adm.rb
module ActiveAdmin
  class ResourceController
    module DataAccess
      # monkey patch to have multiple column sorting as "column1_asc, column2_desc"
      def apply_sorting(chain)
        params[:order] ||= active_admin_config.sort_order

        orders = []
        params[:order].present? && params[:order].split(/_and_/).each do |fragment|
          order_clause = OrderClause.new active_admin_config, fragment
          if order_clause.valid?
            orders << order_clause.to_sql
          end
        end

        if orders.empty?
          chain
        else
          chain.reorder(orders.shift).order(orders)
        end
      end
    end
  end
end
