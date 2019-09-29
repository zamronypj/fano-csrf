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

    TBootstrapApp = class(TSimpleSockFastCGIWebApplication)
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
    protected
        procedure buildDependencies(const container : IDependencyContainer); override;
        procedure buildRoutes(const container : IDependencyContainer); override;
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


    procedure TBootstrapApp.buildConfig(const container : IDependencyContainer);
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

    procedure TBootstrapApp.buildAppMiddleware(const container : IDependencyContainer);
    begin
        container.add(GuidToString(IMiddlewareList), TMiddlewareListFactory.create());
        container.alias(GuidToString(IMiddlewareLinkList), GuidToString(IMiddlewareList));
    end;

    procedure TBootstrapApp.buildDispatcher(
        const container : IDependencyContainer;
        const config : IAppConfiguration
    );
    begin
        container.add(
            GuidToString(IDispatcher),
            TSessionDispatcherFactory.create(
                container.get(GuidToString(IMiddlewareLinkList)) as IMiddlewareLinkList,
                container.get(GuidToString(IRouteMatcher)) as IRouteMatcher,
                TRequestResponseFactory.create(),
                container.get(GuidToString(ISessionManager)) as ISessionManager,
                (TCookieFactory.create()).domain(config.getString('cookie.domain')),
                config.getInt('cookie.maxAge')
            )
        );
    end;

    procedure TBootstrapApp.buildCsrfMiddleware(
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

    procedure TBootstrapApp.buildSessionManager(
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

    procedure TBootstrapApp.buildDependencies(const container : IDependencyContainer);
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

    procedure TBootstrapApp.buildRoutes(const container : IDependencyContainer);
    var router : IRouter;
    begin
        router := container.get(GUIDToString(IRouter)) as IRouter;
        try
            {$INCLUDE Routes/routes.inc}
        finally
            router := nil;
        end;
    end;
end.
