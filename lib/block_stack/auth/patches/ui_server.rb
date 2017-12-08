# TODO Figure out how to implement something like the code below but better...

# module BlockStack
#   class Server
#
#     alias __build_main_menu build_main_menu if defined?(Menu)
#
#     def self.build_main_menu
#       return nil unless defined?(Menu)
#       menu = __build_main_menu
#       if current_user
#         menu.add_items(
#           title: current_user.name,
#           fa_icon: 'user-circle',
#           sort: 100,
#           attributes: {
#             class: 'float-right'
#           },
#           items: [
#             {
#               title: 'Log Out',
#               fa_icon: 'sign-out',
#               attributes: {
#                 href: '/session/logout'
#               }
#             }
#           ]
#         )
#       end
#       menu
#     end
#   end
# end
