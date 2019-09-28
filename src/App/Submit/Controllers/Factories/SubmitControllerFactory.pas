(*!------------------------------------------------------------
 * [[APP_NAME]] ([[APP_URL]])
 *
 * @link      [[APP_REPOSITORY_URL]]
 * @copyright Copyright (c) [[COPYRIGHT_YEAR]] [[COPYRIGHT_HOLDER]]
 * @license   [[LICENSE_URL]] ([[LICENSE]])
 *------------------------------------------------------------- *)
unit SubmitControllerFactory;

interface

uses
    fano;

type

    (*!-----------------------------------------------
     * Factory for controller TSubmitController
     *
     * @author [[AUTHOR_NAME]] <[[AUTHOR_EMAIL]]>
     *------------------------------------------------*)
    TSubmitControllerFactory = class(TFactory, IDependencyFactory)
    public
        function build(const container : IDependencyContainer) : IDependency; override;
    end;

implementation

uses
    sysutils,

    {*! -------------------------------
        unit interfaces
    ----------------------------------- *}
    SubmitController;

    function TSubmitControllerFactory.build(const container : IDependencyContainer) : IDependency;
    var fileReader : IFileReader;
        templateParser : ITemplateParser;
        config : IAppConfiguration;
    begin
        config := container.get(GuidToString(IAppConfiguration)) as IAppConfiguration;
        templateParser:= TSimpleTemplateParser.create('{{', '}}');
        fileReader:= TStringFileReader.create();
        result := TSubmitController.create(
            TTemplateView.create(
                //our application binary is in public directory
                //so we need to go up one level to get correct path
                extractFileDir(getCurrentDir()) + '/resources/Templates/Submit/index.html',
                templateParser,
                fileReader
            ),
            (TViewParameters.create() as IViewParameters)
                .setVar('baseUrl', config.getString('baseUrl'))
                .setVar('appName', config.getString('appName'))
        );
    end;
end.
