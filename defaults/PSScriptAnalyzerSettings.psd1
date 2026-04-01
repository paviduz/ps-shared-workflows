# PSScriptAnalyzer default settings for ps-shared-workflows
# ---------------------------------------------------------------------------
# Used as the fallback when a calling repository does not provide its own
# PSScriptAnalyzerSettings.psd1.
#
# Calling repositories should copy
# .github/skills/ps-quality-pipeline/templates/PSScriptAnalyzerSettings.psd1
# from paviduz/Homelab-Agent-Platform-Plan to their repo root and customise it.
# ---------------------------------------------------------------------------
@{
    Severity = @('Error', 'Warning')

    ExcludeRules = @()

    IncludeDefaultRules = $true

    Rules = @{
        PSUseConsistentIndentation = @{
            Enable              = $true
            IndentationSize     = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind                = 'space'
        }

        PSUseConsistentWhitespace = @{
            Enable                          = $true
            CheckInnerBrace                 = $true
            CheckOpenBrace                  = $true
            CheckOpenParen                  = $true
            CheckOperator                   = $true
            CheckPipe                       = $true
            CheckPipeForRedundantWhitespace = $true
            CheckSeparator                  = $true
            CheckParameter                  = $false
        }

        PSPlaceOpenBrace = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace = @{
            Enable             = $true
            NewLineAfter       = $false
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore  = $false
        }

        PSProvideCommentHelp = @{
            Enable                  = $true
            ExportedOnly            = $true
            BlockComment            = $true
            VSCodeSnippetCorrection = $false
            Placement               = 'before'
        }

        PSAvoidLongLines = @{
            Enable            = $true
            MaximumLineLength = 120
        }

        PSAlignAssignmentStatement = @{
            Enable = $false
        }
    }
}
