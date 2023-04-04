package webdriver

import (
	"log"
	"os"
	"time"

	"github.com/linweiyuan/go-chatgpt-api/api"
	"github.com/tebeka/selenium"
	"github.com/tebeka/selenium/chrome"
)

var WebDriver selenium.WebDriver

//goland:noinspection GoUnhandledErrorResult
func init() {
	chromeArgs := []string{
		"--no-sandbox",
		"--disable-gpu",
		"--disable-dev-shm-usage",
		"--disable-blink-features=AutomationControlled",
		"--headless=new",
	}

	networkProxyServer := os.Getenv("NETWORK_PROXY_SERVER")
	if networkProxyServer != "" {
		chromeArgs = append(chromeArgs, "--proxy-server="+networkProxyServer)
	}

	chatgptProxyServer := os.Getenv("CHATGPT_PROXY_SERVER")
	if chatgptProxyServer == "" {
		log.Fatal("Please set ChatGPT proxy server first")
	}
	var err error
	WebDriver, err = selenium.NewRemote(selenium.Capabilities{
		"chromeOptions": chrome.Capabilities{
			Args:            chromeArgs,
			ExcludeSwitches: []string{"enable-automation"},
		},
	}, chatgptProxyServer)

	if err != nil {
		log.Fatalf("Failed to create WebDriver: %v", err)
		os.Exit(1)
	}
	LoadPageAndHandleCaptcha()

	WebDriver.SetAsyncScriptTimeout(time.Second * api.ScriptExecutionTimeout)
}

//goland:noinspection GoUnhandledErrorResult
func LoadPageAndHandleCaptcha() {
	WebDriver.Get(api.ChatGPTUrl)
	HandleCaptcha(WebDriver)
}
