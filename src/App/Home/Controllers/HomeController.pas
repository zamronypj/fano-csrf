(*!------------------------------------------------------------
 * [[APP_NAME]] ([[APP_URL]])
 *
 * @link      [[APP_REPOSITORY_URL]]
 * @copyright Copyright (c) [[COPYRIGHT_YEAR]] [[COPYRIGHT_HOLDER]]
 * @license   [[LICENSE_URL]] ([[LICENSE]])
 *------------------------------------------------------------- *)
unit HomeController;

interface

uses

    fano;

type

    (*!-----------------------------------------------
     * controller that handle route :
     * /home
     *
     * See Routes/Home/routes.inc
     *
     * @author [[AUTHOR_NAME]] <[[AUTHOR_EMAIL]]>
     *------------------------------------------------*)
    THomeController = class(TController)
    private
        fSessionManager : ISessionManager;
    public
        constructor create(
            const viewInst : IView;
            const viewParamsInst : IViewParameters;
            const sessMgr : ISessionManager
        );
        destructor destroy(); override;
        function handleRequest(
            const request : IRequest;
            const response : IResponse;
            const args : IRouteArgsReader
        ) : IResponse; override;

    end;

implementation

    constructor THomeController.create(
        const viewInst : IView;
        const viewParamsInst : IViewParameters;
        const sessMgr : ISessionManager
    );
    begin
        inherited create(viewInst, viewParamsInst);
        fSessionManager := sessMgr;
    end;

    destructor THomeController.destroy();
    begin
        fSessionManager := nil;
        inherited destroy();
    end;

    function THomeController.handleRequest(
        const request : IRequest;
        const response : IResponse;
        const args : IRouteArgsReader
    ) : IResponse;
    var sess : ISession;
    begin
        sess := fSessionManager.getSession(request);
        viewParams.setVar('csrfName', sess.getVar('csrf_name'));
        viewParams.setVar('csrfToken', sess.getVar('csrf_token'));
        result := inherited handleRequest(request, response, args);
    end;

end.
