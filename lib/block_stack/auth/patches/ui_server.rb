# module BlockStack
#   class Server
#
#     if defined?(Menu)
#       require_relative 'menu'
#
#       alias _menu menu
#
#       def menu
#         return _menu unless config.authorize
#         items = _menu.items_for(current_login)
#         Menu.new(_menu.serialize.except(:items).merge(items: items))
#       end
#     end
#   end
# end
