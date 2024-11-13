<h1 align="center">hpc_base_plus_manifest</h1>

| Build       | State |
|-------------|-------|
| Nightly     |  [![Release Status](https://jenkins-rm-swp-vc-hpc.cmo.conti.de/job/hpc_base_plus_manifest/job/metanight/badge/icon)](https://jenkins-rm-swp-vc-hpc.cmo.conti.de/job/hpc_base_plus_manifest/job/metanight/)|
| Build     |  [![Build Status](https://jenkins-rm-swp-vc-hpc.cmo.conti.de/job/hpc_base_plus_manifest/job/metamerge/badge/icon)](https://jenkins-rm-swp-vc-hpc.cmo.conti.de/job/hpc_base_plus_manifest/job/metamerge/)|

This repository is the super repository for HPC Base Plus. All sub repositories used in HPC Base Plus are
defined in the manifest files (see table below).

All integration jobs run on the SW Foundation Assets Jenkins master: https://jenkins-rm-swp-vc-hpc.cmo.conti.de/


## Copyright and License

Copyright (C) 2024 Continental AG and subsidiaries. 

License Information: [License](LICENSES/LicenseRef-Continental-1.0)

<!--
SPDX-FileCopyrightText: Copyright (C) 2024 Continental AG and subsidiaries
 
SPDX-License-Identifier: LicenseRef-Continental-1.0
-->

## HowTo: use and contribute

Check out this repository using the [git-repo] tool.

```shell-script
repo init -u git@github-vni.geo.conti.de:rm-swp-vc-hpc/hpc_base_plus_manifest.git -b 1.0-dev -m default.xml
repo sync
```

Refer to the Confluence Page: https://confluence.auto.continental.cloud/display/SPACE2225/HPC+Base+Plus+-+Build+Instruction

### Mega Merge

To integrate new content in one of the linked sub-repositories HPC Base Plus uses [Mega Merge].
Please refer to the Mega Merge guideline on how to use it.

Refer to the Confluence Page: https://confluence.auto.continental.cloud/display/SPACE2225/Megamerge+usage+guideline

**DO NOT merge Pull Requests manually!!!**

Use

+ Label **_check_** to build and test your Pull Request without merge.
+ Label **_merge_** to build and test your change. In case of success and an approved review the Pull Request will be merged automatically.

## List of files and purpose

| File name | Purpose |
| --------- | ------- |
| `.github/ccif.yaml` | Config file for CCIF |
| `.ci/Jenkinsfile` | CCIF based implementation for the CI pipeline |
| `default.xml` | Top level manifest file for the LICOOS project. |

---

## Hint about protected and feature branches
The branch protection rule is set to pattern "\*". 

This will automatically protect all branches. To avoid that feature or prototype branches become protected as well, they should include a "/" pattern. 

E.g. feature/\<Jira issue ID\> or ft/\<Jira issue ID\> or  pt/\<Jira issue ID\> or ...
 
From the Github docs:
 
 *You can create a rule for all current and future branches in your repository with the wildcard syntax *. Because GitHub uses the File::FNM_PATHNAME flag for the File.fnmatch syntax, the wildcard does not match directory separators (/). For example, qa/* will match all branches beginning with qa/ and containing a single slash. You can include multiple slashes with qa/**/*, and you can extend the qa string with qa**/**/* to make the rule more inclusive.*
