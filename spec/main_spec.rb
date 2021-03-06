class UsersTestController < UIViewController
  attr_accessor :user_id

  def initWithParams(params = {})
    init()
    self.user_id = params[:user_id]
    self
  end
end

class NoParamsController < UIViewController
end

class LoginController < UIViewController
end

class ConfigurableController < UIViewController
  attr_accessor :configured

  def init
    super.tap do |controller|
      controller.configured = false
    end
  end
end

describe "the url router" do
  before do
    @router = Routable::Router.new

    @nav_controller = UINavigationController.alloc.init
    @nav_controller.setViewControllers([], animated: false)
    @nav_controller.viewControllers.count.should == 0
  end

  describe '#open' do
    it 'accepts a configuration block' do
      url = 'configured'
      @router.navigation_controller = @nav_controller
      @router.map(url, ConfigurableController, shared: true)

      @router.open(url) do |controller|
        controller.configured = true
      end

      controller = @router.controller_for_url(url)
      controller.configured.should.be.true
    end
  end

  def make_test_controller_route
    format = "users/:user_id"
    @router.map(format, UsersTestController)
    @router.routes.should == {format => {:klass => UsersTestController}}
  end

  it "maps the correct urls" do
    make_test_controller_route

    user_id = "1001"
    controller = @router.controller_for_url("users/#{user_id}")
    controller.class.should == UsersTestController
    controller.user_id.should == user_id
  end

  it "opens urls with no params" do
    @router.navigation_controller = @nav_controller
    @router.map("url", NoParamsController)
    @router.open("url")
    @router.navigation_controller.viewControllers.count.should == 1
  end

  it "opens nav controller to url" do
    @router.navigation_controller = @nav_controller
    make_test_controller_route
    @router.open("users/3")

    @nav_controller.viewControllers.count.should == 1
    @nav_controller.viewControllers.last.class.should == UsersTestController    
  end

  it "uses the shared properties correctly" do
    shared_format = "users"
    format= "users/:user_id"

    @router.map(format, UsersTestController)
    @router.map(shared_format, UsersTestController, shared: true)
    @router.navigation_controller = @nav_controller
    @router.open("users/3")
    @router.open("users/4")
    @router.open("users")
    @router.open("users/5")

    @nav_controller.viewControllers.count.should == 4

    @router.open("users")
    @nav_controller.viewControllers.count.should == 3
  end

  it "should use transition option" do
    [:cover, :flip, :dissolve, :curl].each do |transition|
      url = "login/#{transition.to_s}"
      @router.map(url, LoginController, modal: true, transition:transition)
      controller = @router.controller_for_url(url)
      controller.modalTransitionStyle.should == Routable::Router::TRANSITION_STYLES[transition]
    end
  end

  it "should raise error when transition is unexpected value" do
    lambda do
      @router.map("login", LoginController, modal: true, transition: :unexpected)
    end.should.raise(ArgumentError)
  end

  it "should use presentation option" do
    [:full_screen, :page_sheet, :form_sheet, :current].each do |presentation|
      url = "login/#{presentation.to_s}"
      @router.map(url, LoginController, modal: true, presentation:presentation)
      controller = @router.controller_for_url(url)
      controller.modalPresentationStyle.should == Routable::Router::PRESENTATION_STYLES[presentation]
    end
  end

  it "should raise error when presentation is unexpected value" do
    lambda do
      @router.map("login", LoginController, modal: true, presentation: :unexpected)
    end.should.raise(ArgumentError)
  end

  it "should work with callback blocks" do
    @called = false
    @router.map("logout") do
      @called = true
    end

    @router.open("logout")
    @called.should == true
  end

  it "should work with callback blocks & params" do
    @called = false
    @router.map("logout/:id") do |params|
      @called = params[:id]
    end

    @router.open("logout/123")
    @called.should == "123"
  end

  describe 'reset option' do
    it 'resets the navigation controller stack with the target controller' do
      @router.navigation_controller = @nav_controller
      @router.map('start', NoParamsController)
      @router.map('reset', NoParamsController, resets: true)

      @router.open('start')
      @router.open('reset')

      @router.navigation_controller.viewControllers.count.should == 1
    end
  end
end
