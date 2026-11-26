from collections.abc import Callable
from typing import Any


def add_zipfoundation(objects: dict[str, Any], obj: Callable[..., str], target: str, project: str) -> None:
    package = obj('zipfoundation-package', 'XCRemoteSwiftPackageReference',
                  repositoryURL='https://github.com/weichsel/ZIPFoundation.git',
                  requirement={'kind': 'exactVersion', 'version': '0.9.20'})
    product = obj('zipfoundation-product', 'XCSwiftPackageProductDependency', package=package, productName='ZIPFoundation')
    framework = obj('zipfoundation-framework', 'PBXBuildFile', productRef=product)
    objects[target].setdefault('packageProductDependencies', []).append(product)
    objects[project].setdefault('packageReferences', []).append(package)
    phase = next(objects[key] for key in objects[target]['buildPhases']
                 if objects[key]['isa'] == 'PBXFrameworksBuildPhase')
    phase['files'].append(framework)
