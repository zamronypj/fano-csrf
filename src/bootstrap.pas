(*!------------------------------------------------------------
 * [[APP_NAME]] ([[APP_URL]])
 *
 * @link      [[APP_REPOSITORY_URL]]
 * @copyright Copyright (c) [[COPYRIGHT_YEAR]] [[COPYRIGHT_HOLDER]]
 * @license   [[LICENSE_URL]] ([[LICENSE]])
 *------------------------------------------------------------- *)
unit bootstrap;

interface

uses

    fano;

type

    TAppServiceProvider = class(TDaemonAppServiceProvider)
    private
        procedure buildConfig(const container : IDependencyContainer);
        procedure buildSessionManager(
            const container : IDependencyContainer;
            const config : IAppConfiguration
        );
        procedure buildAppMiddleware(
            const container : IDependencyContainer
        );
        procedure buildDispatcher(
            const container : IDependencyContainer;
            const config : IAppConfiguration
        );
        procedure buildCsrfMiddleware(
            const container : IDependencyContainer;
            const config : IAppConfiguration
        );
    public
        procedure register(const container : IDependencyContainer); override;
    end;

    TAppRoutes = class(TRouteBuilder)
    public
        procedure buildRoutes(
            const container : IDependencyContainer;
            const router  : IRouter
        ); override;
    end;

implementation

uses
    sysutils

    (*! -------------------------------
     *   controllers factory
     *----------------------------------- *)
    {---- put your controller factory here ---},
    HomeControllerFactory,
    SubmitControllerFactory;


    procedure TAppServiceProvider.buildConfig(const container : IDependencyContainer);
    begin
        container.add(
            GuidToString(IAppConfiguration),
            TJsonFileConfigFactory.create(
                //our application binary is in public directory
                //so we need to go up one level to get correct path
                extractFileDir(getCurrentDir()) + '/config/config.json'
            )
        );
    end;

    procedure TAppServiceProvider.buildAppMiddleware(const container : IDependencyContainer);
    begin
        container.add(GuidToString(IMiddlewareList), TMiddlewareListFactory.create());
        container.alias(GuidToString(IMiddlewareLinkList), GuidToString(IMiddlewareList));
    end;

    procedure TAppServiceProvider.buildDispatcher(
        const container : IDependencyContainer;
        const config : IAppConfiguration
    );
    begin
        container.add(
            GuidToString(IDispatcher),
            TSessionDispatcherFactory.create(
                container.get(GuidToString(IMiddlewareLinkList)) as IMiddlewareLinkList,
                getRouteMatcher(),
                TRequestResponseFactory.create(),
                container.get(GuidToString(ISessionManager)) as ISessionManager,
                (TCookieFactory.create()).domain(config.getString('cookie.domain')),
                config.getInt('cookie.maxAge')
            )
        );
    end;

    procedure TAppServiceProvider.buildCsrfMiddleware(
        const container : IDependencyContainer;
        const config : IAppConfiguration
    );
    var appMiddlewares : IMiddlewareList;
    begin
        container.add(
            'verifyCsrfToken',
            TCsrfMiddlewareFactory.create(config.getString('secretKey'))
        );
        appMiddlewares := container.get(GuidToString(IMiddlewareList)) as IMiddlewareList;
        appMiddlewares.add(container.get('verifyCsrfToken') as IMiddleware)
    end;

    procedure TAppServiceProvider.buildSessionManager(
        const container : IDependencyContainer;
        const config : IAppConfiguration
    );
    begin
        container.add(
            GuidToString(ISessionManager),
            TJsonFileSessionManagerFactory.create(
                config.getString('session.name'),
                //our application binary is in public directory
                //so we need to go up one level to get correct path
                extractFileDir(getCurrentDir()) + '/' + config.getString('session.dir')
            )
        );
    end;

    procedure TAppServiceProvider.register(const container : IDependencyContainer);
    var config : IAppConfiguration;
    begin
        buildConfig(container);
        buildAppMiddleware(container);
        config := container.get(GuidToString(IAppConfiguration)) as IAppConfiguration;
        buildSessionManager(container, config);
        buildDispatcher(container, config);
        buildCsrfMiddleware(container, config);
        {$INCLUDE Dependencies/dependencies.inc}
    end;

    procedure TAppRoutes.buildRoutes(
        const container : IDependencyContainer;
        const router : IRouter
    );
    begin
        {$INCLUDE Routes/routes.inc}
    end;
end.
