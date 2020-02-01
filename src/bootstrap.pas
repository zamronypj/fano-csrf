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
        procedure buildCsrfMiddleware(
            const ctnr : IDependencyContainer;
            const config : IAppConfiguration
        );
    protected
        function buildAppConfig(const ctnr : IDependencyContainer) : IAppConfiguration; override;
        function buildDispatcher(
            const ctnr : IDependencyContainer;
            const routeMatcher : IRouteMatcher;
            const config : IAppConfiguration
        ) : IDispatcher; override;

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

    function TAppServiceProvider.buildAppConfig(const ctnr : IDependencyContainer) : IAppConfiguration;
    begin
        ctnr.add(
            GuidToString(IAppConfiguration),
            TJsonFileConfigFactory.create(
                //our application binary is in public directory
                //so we need to go up one level to get correct path
                extractFileDir(getCurrentDir()) + '/config/config.json'
            )
        );
        result := ctnr.get(GuidToString(IAppConfiguration)) as IAppConfiguration;
    end;

    function TAppServiceProvider.buildDispatcher(
        const ctnr : IDependencyContainer;
        const routeMatcher : IRouteMatcher;
        const config : IAppConfiguration
    ) : IDispatcher;
    begin
        ctnr.add('appMiddlewares', TMiddlewareListFactory.create());

        ctnr.add(
            GuidToString(ISessionManager),
            TJsonFileSessionManagerFactory.create(
                config.getString('session.name'),
                //our application binary is in public directory
                //so we need to go up one level to get correct path
                extractFileDir(getCurrentDir()) + '/' + config.getString('session.dir')
            )
        );

        ctnr.add(
            GuidToString(IDispatcher),
            TSessionDispatcherFactory.create(
                ctnr.get('appMiddlewares') as IMiddlewareLinkList,
                routeMatcher,
                TRequestResponseFactory.create(),
                ctnr.get(GuidToString(ISessionManager)) as ISessionManager,
                (TCookieFactory.create()).domain(config.getString('cookie.domain')),
                config.getInt('cookie.maxAge')
            )
        );
        result := ctnr.get(GuidToString(IDispatcher)) as IDispatcher;
    end;

    procedure TAppServiceProvider.buildCsrfMiddleware(
        const ctnr : IDependencyContainer;
        const config : IAppConfiguration
    );
    var appMiddlewares : IMiddlewareList;
    begin
        ctnr.add(
            'verifyCsrfToken',
            TCsrfMiddlewareFactory.create(config.getString('secretKey'))
        );
        appMiddlewares := ctnr.get('appMiddlewares') as IMiddlewareList;
        appMiddlewares.add(ctnr.get('verifyCsrfToken') as IMiddleware);
    end;

    procedure TAppServiceProvider.register(const container : IDependencyContainer);
    var config : IAppConfiguration;
    begin
        config := container.get(GuidToString(IAppConfiguration)) as IAppConfiguration;
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
