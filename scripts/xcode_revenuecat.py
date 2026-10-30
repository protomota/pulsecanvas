from collections.abc import Callable
from typing import Any


def add_revenuecat(objects: dict[str, Any], obj: Callable[..., str], target: str, project: str) -> None:
    package = obj('revenuecat-package', 'XCRemoteSwiftPackageReference',
                  repositoryURL='https://github.com/RevenueCat/purchases-ios.git',
                  requirement={'kind': 'exactVersion', 'version': '5.99.0'})
    product = obj('revenuecat-product', 'XCSwiftPackageProductDependency', package=package, productName='RevenueCat')
    framework = obj('revenuecat-framework', 'PBXBuildFile', productRef=product)
    objects[target]['packageProductDependencies'] = [product]
    objects[project]['packageReferences'] = [package]
    phase = next(objects[key] for key in objects[target]['buildPhases']
                 if objects[key]['isa'] == 'PBXFrameworksBuildPhase')
    phase['files'].append(framework)
