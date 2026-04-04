class LeftbarComponent extends HTMLElement {
    connectedCallback() {
        this.outerHTML = ` <div class="app-sidenav">

                                  <!-- Brand Logo -->
                                  <div class="logo-box">
                                      <!-- Brand Logo Light -->
                                      <a href="index.html">
                                          <img src="assets/images/logo-light.png" alt="logo" width="48">
                                      </a>

                                  </div>

                                  <!--- Menu -->
                                  <div class="h-100" data-simplebar>
                                      <ul class="menu">

                                          <li class="menu-title">Getting Started</li>

                                          <li class="menu-item">
                                              <a href="introduction.html" class="menu-link">
                                                  <span class="menu-icon"><i class="uil uil-estate font-18 me-1"></i></span>
                                                  <span class="menu-text"> Introduction </span>
                                              </a>
                                          </li>

                                          <li class="menu-item">
                                              <a href="installation.html" class="menu-link">
                                                  <span class="menu-icon"><i class="uil uil-processor font-18 me-1"></i></span>
                                                  <span class="menu-text"> Installation </span>
                                              </a>
                                          </li>

                                          <li class="menu-item">
                                              <a href="changelog.html" class="menu-link">
                                                  <span class="menu-icon"><i class="uil uil-book-open font-18 me-1"></i></span>
                                                  <span class="menu-text"> Changelog </span>
                                              </a>
                                          </li>

                                      </ul>
                                      <!--- End Menu -->
                                      <div class="clearfix"></div>
                                  </div>
                              </div>`;
    }
}

class TopbarComponent extends HTMLElement {
    connectedCallback() {
        this.outerHTML = `  <div class="navbar-custom">
                <div class="topbar px-2">
                    <div class="topbar-menu d-flex align-items-center gap-lg-2 gap-1">
                        <!-- Sidebar Menu Toggle Button -->
                        <button class="button-toggle-menu">
                            <i data-feather="menu"></i>
                        </button>
                    </div>

                    <ul class="topbar-menu d-flex align-items-center gap-3">

                        <li class="d-none d-md-inline-block">
                            <span class="nav-link">
                                <span class="badge bg-danger font-16"> v1.0</span>
                            </span>
                        </li>
                    </ul>
                </div>
            </div>`;
    }
}

customElements.define("x-leftbar", LeftbarComponent);
customElements.define("x-topbar", TopbarComponent);
