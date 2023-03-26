#!/bin/bash -e -o pipefail

.PHONY: docc keys requirebrew requirejq

docc: requirejq
	rm -rf docs
	swift build
	DOCC_JSON_PRETTYPRINT=YES
	swift package \
 	--allow-writing-to-directory ./docs \
	generate-documentation \
 	--target OpenAIClient \
 	--output-path ./docs \
 	--transform-for-static-hosting \
 	--hosting-base-path OpenAIClient \
	--emit-digest
	cat docs/linkable-entities.json | jq '.[].referenceURL' -r | sort > docs/all_identifiers.txt
	sort docs/all_identifiers.txt | sed -e "s/doc:\/\/OpenAIClient\/documentation\\///g" | sed -e "s/^/- \`\`/g" | sed -e 's/$$/``/g' > docs/all_symbols.txt
	@echo "Check https://janodevorg.github.io/OpenAIClient/documentation/openaiclient/"
	@echo ""

keys:
	@echo
	@echo "This script creates the credentials file that enables integration tests."
	@echo "These tests are useful for debugging and to test this library, but note"
	@echo "they may alter data on your account. I suggest you run them manually." 
	@echo 	
	@echo "Please paste your api key:"
	@echo "(you can find it at https://platform.openai.com/account/api-keys)"
	@read apiKey; \
	echo ""; \
	echo "Please paste your organization ID:"; \
	echo "(you can find it at https://platform.openai.com/account/org-settings)"; \
	read organizationId; \
	echo ""; \
	echo "Please enter your hostname if you intend to debug in Proxyman (otherwise press enter)"; \
	echo "(you can find it at Apple > System Settings > General > Sharing > Local hostname)"; \
	read hostName; \
	filename="Tests/Integration/resources/realKeys.json"; \
	echo '{' > $$filename; \
	echo '    "apiKey": "'$$apiKey'",' >> $$filename; \
	echo '    "organizationId": "'$$organizationId'",' >> $$filename; \
	echo '    "hostName": "'$$hostName'"' >> $$filename; \
	echo '}' >> $$filename; \
	echo ""; \
	echo "JSON file created at $$filename"; \
	cat $$filename

test:
	set -o pipefail && xcodebuild test -scheme "OpenAIClient" -destination "OS=16.2,name=iPhone 14 Pro" -skipPackagePluginValidation | xcpretty
	set -o pipefail && xcodebuild test -scheme "OpenAIClient" -destination "platform=macOS,arch=arm64" -skipPackagePluginValidation | xcpretty
	set -o pipefail && xcodebuild test -scheme "OpenAIClient" -destination "platform=macOS,arch=arm64,variant=Mac Catalyst" -skipPackagePluginValidation | xcpretty
	set -o pipefail && xcodebuild test -scheme "OpenAIClient" -destination "platform=tvOS Simulator,name=Apple TV 4K (3rd generation)" -skipPackagePluginValidation | xcpretty

requirebrew:
	@if ! command -v brew &> /dev/null; then echo "Please install brew from https://brew.sh/"; exit 1; fi

requirejq: requirebrew
	@if ! command -v jq &> /dev/null; then echo "Please install jq using 'brew install jq'"; exit 1; fi
