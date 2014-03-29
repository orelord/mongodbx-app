/*global module:false*/
module.exports = function(grunt) {

  grunt.initConfig({

    pkg: grunt.file.readJSON('package.json'),

    banner: '/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - ' +
        '<%= grunt.template.today("yyyy-mm-dd") %>\n' +
        '<%= pkg.homepage ? "* " + pkg.homepage + "\\n" : "" %>' +
        '* Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>;' +
        ' Licensed <%= _.pluck(pkg.licenses, "type").join(", ") %> */\n',

    path:{
        scripts: {
            src:'src/app/scripts',
            dist:'./app/scripts'
        },
        styles: {
            src:'src/app/styles',
            dist:'./app/styles'
        }
    },

    concat: {
      options: {
        banner: '<%= banner %>',
        stripBanners: true
      },
      scripts: {
        src: ['<%= path.scripts.src %>/**/*.js'],
        dest: '<%= path.scripts.dist %>/app.js'
      },
      styles: {
        src: ['<%= path.styles.src %>/**/*.css'],
        dest: '<%= path.styles.dist %>/app.css'
      }
    },

    uglify: {
      options: {
        banner: '<%= banner %>'
      },
      scripts: {
        src: '<%= concat.scripts.dest %>',
        dest: '<%= path.scripts.dist %>/app.min.js'
      }
    },

    cssmin: {
      styles: {
        src: '<%= concat.styles.dest %>',
        dest: '<%= path.styles.dist %>/app.min.css'
      }
    },

    htmlmin: {
        dist: {
            options: {
                removeComments: true,
                collapseWhitespace: true
            },
            files: {
                'index.html': 'src/index.html'
            }
        }
    },

    jshint: {
      options: {
        jshintrc:true
      },
      gruntfile: {
        src: ['Gruntfile.js', '.jshintrc']
      },
      src: {
        src: ['src/app/scripts/**/*.js']
      }
    },

    bowerInstall: {
        target: {
            src: ['src/**/*.html'],
            dependencies:true,
            devDependencies:false,
            exclude: [],
            fileTypes: {},
            ignorePath: ''
        }
    },

    watch: {
      gruntfile: {
        files: '<%= jshint.gruntfile.src %>',
        tasks: ['jshint:gruntfile']
      },
      src: {
        files: ['<%= jshint.src.src %>'],
        tasks: ['jshint:src'],
        options:{
          reload:true
        }
      }
    },

    copy: {
        main:{
            cwd: 'src/',
            expand: true,
            nonull:true,
            src: ['app/components/**/*.min.*', 'app/images/**'],
            dest:'./'
        }
    },

    connect: {
      server:{
        options:{
          port:4000,
          hostname:'0.0.0.0',
          base:'src'
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-htmlmin');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-connect');
  grunt.loadNpmTasks('grunt-bower-install');
  grunt.loadNpmTasks('grunt-contrib-copy');

  grunt.registerTask('server', ['connect','watch']);
  grunt.registerTask('default', ['htmlmin', 'jshint',  'concat', 'uglify', 'cssmin', 'copy']);

};
