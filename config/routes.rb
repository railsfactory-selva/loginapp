ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority. 

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # Login and Signup
   map.login '/user/login', :controller=>'manage_profiles', :action => 'login_manage'
   map.new_user '/user/new_user', :controller=>'manage_profiles', :action=>'new_user'
   map.login_create '/login_create', :controller=>'manage_profiles', :action => 'login_create'
   map.login_retry '/login_retry', :controller=>'manage_profiles', :action => 'login_retry'
   map.registration '/registration', :controller=>'manage_profiles', :action => 'registration'
   map.registration '/signup_create', :controller=>'manage_profiles', :action => 'signup_create'
   map.registration_error '/signup_retry', :controller=>'manage_profiles', :action => 'signup_retry'
   map.activation '/activation', :controller=>'manage_profiles', :action => 'activation'
   map.signup_confirmation '/signup_confirmation', :controller=>'manage_profiles', :action => 'signup_confirmation'
   map.change_password '/change_password', :controller=>'manage_profiles', :action => 'reset_password'
   map.reset_password '/reset_password', :controller=>'manage_profiles', :action => 'change_password'
   map.login_reset_password '/login_reset_password', :controller=>'manage_profiles', :action => 'login_reset_password'
   map.reset_create '/reset_create', :controller=>'manage_profiles', :action => 'reset_create'
   map.reset_confirmation '/reset_password_confirmation', :controller=>'manage_profiles', :action => 'reset_password_confirmation'
   map.reset_error '/reset_password_retry', :controller=>'manage_profiles', :action => 'reset_password_error'
   map.resend_mobile_pin '/resend_mobile_pin', :controller=>'manage_profiles', :action => 'resend_mobile_pin'
   map.resend_email_pin '/resend_email_pin', :controller=>'manage_profiles', :action => 'resend_email_pin'
   map.validate_pin '/validate_pin', :controller=>'manage_profiles', :action => 'validate_pin'
   map.off_network_registration '/off_network_registration', :controller=>'manage_profiles', :action => 'off_network_registration'
   map.dummy_page '/on_net_consent', :controller=>'manage_profiles', :action => 'on_net_consent'
  # Manage Consent
  map.manage_consent '/manage_consent', :controller=>'manage_consent', :action => 'manage_consent'
  map.consent_application '/consent_application', :controller=>'manage_consent', :action => 'consent_application'
  map.revoke_application '/revoke_consent', :controller=>'manage_consent', :action => 'revoke_application'
  map.applications '/user/authorize/list', :controller=>'manage_consent', :action => 'applications'
  # Consent
  map.consent_application '/user/issueconsent', :controller=>'manage_profiles', :action => 'consent_app'
  map.consent_confirmation '/consent_confirmation', :controller=>'consent', :action => 'consent_confirmation'
  map.payments '/payment/userAuthenticate', :controller=>'consent', :action => 'payments'
  map.payment_login '/user/payment/login', :controller=>'consent', :action => 'login_manage'
  map.payment_login_create '/payment_login_create', :controller=>'consent', :action => 'login_create'

map.off_net_consent '/off_net_consent', :controller => 'manage_profiles', :action => 'off_net_consent'
map.on_net_aoc_consent '/user/payments/on_net_aoc_consent', :controller => 'consent', :action => 'on_net_aoc_consent'
map.http_on_net_aoc_consent '/user/payments/http_on_net_aoc_consent', :controller => 'consent', :action => 'http_on_net_aoc_consent'
map.off_net_consent_wireless '/off_net_consent_wireless', :controller => 'on_off_network', :action => 'off_net_consent_wireless'
map.on_net_consent_wireless '/user/payments/off_net_consent_wireless', :controller => 'consent', :action => 'off_net_consent_wireless'
map.on_net_aoc_consent_wireless '/user/payments/on_network', :controller => 'consent', :action => 'on_net_aoc_consent_wireless'
map.off_net_aoc_consent_wireless '/user/payments/off_network', :controller => 'consent', :action => 'off_net_aoc_consent_wireless'
map.off_net_send_pin '/off_net_validate_pin', :controller => 'on_off_network', :action => 'off_net_validate_pin'
map.verify_onpin '/verify_onpin', :controller => 'on_off_network', :action => 'verify_onpin'
map.verify_pin '/verify_pin', :controller => 'on_off_network', :action => 'verify_pin'
map.resend_pin '/resend_pin', :controller => 'on_off_network', :action => 'resend_pin'
map.thank_you '/thank_you', :controller => 'on_off_network', :action => 'thank_you'

map.off_net_aoc_send_pin '/payments/off_net_validate_pin', :controller => 'consent', :action => 'off_net_aoc_validate_pin'
map.aoc_verify_onpin '/user/payments/verify_onpin', :controller => 'consent', :action => 'aoc_verify_onpin'
map.aoc_verify_pin '/user/payments/verify_pin', :controller => 'consent', :action => 'aoc_verify_pin'
map.aoc_resend_pin '/user/payments/resend_pin', :controller => 'consent', :action => 'aoc_resend_pin'
map.aoc_thank_you '/user/payments/thank_you', :controller => 'consent', :action => 'aoc_thank_you'

map.login_thank_you '/login_thank_you', :controller => 'manage_profiles', :action => 'login_thank_you'
map.deny_pin '/deny_pin', :controller => 'on_off_network', :action => 'deny_pin'
map.aoc_deny_pin '/payments/deny_pin', :controller => 'consent', :action => 'deny_pin'

map.on_net_consent '/on_net_consent', :controller => 'manage_profiles', :action => 'on_net_consent'
map.http_on_net_consent '/http_on_net_consent', :controller => 'manage_profiles', :action => 'http_on_net_consent'
map.on_net_consent_wireless '/on_net_consent_wireless', :controller => 'on_off_network', :action => 'on_net_consent_wireless'
map.termsnconditions '/termsnconditions', :controller => 'manage_profiles', :action => 'terms_and_conditions'


# MANAGE CONSENT

map.manage_consent_home '/myprofile', :controller => 'manage_consent', :action => 'manage_consent_home'
map.off_net_mc_verify_pin '/user/manageconsent/verify_pin', :controller => 'manage_consent', :action => 'off_net_mc_verify_pin'
map.mc_off_net_validate_pin '/user/manageconsent/validate_pin', :controller => 'manage_consent', :action => 'mc_off_net_validate_pin'
map.mc_resend_pin '/user/manageconsent/resend_pin', :controller => 'manage_consent', :action => 'mc_resend_pin'
map.http_on_net_manageconsent '/user/manageconsent/http_on_net_manageconsent', :controller => 'manage_consent', :action => 'http_on_net_manageconsent'
map.on_network '/user/manageconsent/on_network', :controller => 'manage_consent', :action => 'on_network'
map.mc_verify_onpin '/user/manageconsent/mc_verify_onpin', :controller => 'manage_consent', :action => 'mc_verify_onpin'
map.on_net_manage_consent '/user/manageconsent/on_net_manage_consent', :controller => 'manage_consent', :action => 'on_net_manage_consent'
  # See how all your routes lay out with "rake routes"
  map.root :controller => "manage_profiles", :action => 'login_manage'
    map.error '*a', :controller => 'manage_profiles', :action => 'routing'
  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  #~ map.connect ':controller/:action/:id'
  #~ map.connect ':controller/:action/:id.:format'
end
