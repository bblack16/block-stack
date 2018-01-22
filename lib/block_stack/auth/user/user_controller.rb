module BlockStack
  class UserController < Controller

    self.prefix = nil
    self.api_prefix = nil

    get '/session/logout' do
      name = current_user.display_name
      logout
      redirect '/login', 303, notice: "Goodbye, #{name}."
    end

    get '/login' do
      if current_user
        redirect homepage, 303
      else
        slim :'default/login'
      end
    end

    post '/session/login' do
      if current_user
        redirect homepage, 303, notice: "Hello and welcome, #{current_user.display_name}!"
      else
        redirect '/login', 401
      end
    end

    post_api '/session/register' do
      user = JSON.parse(request.body.read).keys_to_sym
      begin
        u = user_model.new(user)
        if result = u.save
          { result: result, status: :success, message: "Registration completed successfully." }
        else
          { status: :error, message: "Registration failed." }
        end
      rescue InvalidModelError => e
        { result: item.errors, status: :error, message: "Registration failed." }
      rescue => e
        { status: :error, message: "Registration failed: #{e}" }
      end
    end

  end
end
